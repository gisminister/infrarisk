# -*- coding: utf-8 -*-
# Author: bard.romstad@cicero.uio.no
import arcpy
from arcpy import env
import os, sys
import tempfile

class cmrstudy:
    """Class for CICERO Multirisk tool
Methods:
initiateStudyArea(studyDescription=None)
Inserts the necessary records in the cmr database for a new study
If the study already exsist (user defines studyId) then all relevant cmr records are reset

addInputDataset(datasetType {'hazard' | 'element'}, dsFilepath, dsDescription=None)
Attaches an input dataset record to the defined study area in the cmr database.
If an input dataset of the same type already exists for the study, then it is replaced by the new one.

hazardElementIntersection()
Runs the geoprocessing necessary to generate an element hazard intersection table.
The intersection table is then imported to the cmr database so that risk analysis can be performed.
It also creates an output feature layer showing the original elements (but with its features split at each zone-boundary)
The OID of the output layer can be used to join individual features to cmr risk measures
    """
    ########################################
    ###        PRIVATE PROPERTIES        ###
    ########################################
    __studyName = r"cmrStudy"
    __studyId = False
    __sdeConn = False
    #Filename pattern for output ear features
    __earOutputFilename = "{0}\\ear{1}_feat"

    __cmrRequiredSPs = ["cmrSP_setStudyArea","cmrSP_defineInputData","cmrSP_importResults"]

    __sqlExecInitiateStudy = """EXECUTE [cmrSP_setStudyArea] @study_id={0}
                                , @study_name='{1}'
                                , @hazardzone_dataset_filepath='{2}'
                                , @element_dataset_filepath='{3}'
                                , @study_description='{4}'
                                """
    __sqlExecImportResults = """EXECUTE [cmrSP_importResults] @study_id={0}"""

    #Table name for the import table in cmr database
    __cmrImportTable = "cmrT_ImportIntersectionTable"
    __oldWS = None

    #Lists for storing temporary data
    __tmpgisfiles = []
    __tmpws = []
    __tmpdirs = []


    #######################################
    ###        PUBLIC PROPERTIES        ###
    #######################################
    #Mapping between cmrImportTable fields (keys) and input dataset fields
    cmrImportFieldMapping = {'element_feature_id': 'FID_element'
                             , 'hazardzone_feature_id': 'FID_zone'
                             , 'study_id': 'study_id'
                             , 'elementtype_code': 'elementtype_code'
                             , 'route_code': 'route_code'
                             , 'aadt_passenger': 'aadt_passenger'
                             , 'aadt_goods': 'aadt_goods'
                             , 'diversion_time': 'diversion_time'
                             , 'processtype_id': 'processtype_id'
                             , 'event_frequency': 'event_frequency'
                             , 'freq_interval_plus': 'freq_interval_plus'
                             , 'freq_interval_minus': 'freq_interval_minus'
                             , 'element_size': 'Shape_Length'
                             }

    #Output feature
    outputFeatures = None

    #Element hazard intersections shorter than this will be ignored
    minimum_element_size = 1
    #The environment setting for extent that will be used in geoprocessing
    extent = "MINOF"

    ########################################
    ###          PRIVATE METHODS         ###
    ########################################
    def __init__(self, sdeConnFile, outputGDB):
        #Create the sde connection
        self.__sdeConn = self.__sdeSqlConnect(sdeConnFile)
        if self.__sdeConn:
            #Define path to cmrImportTable
            self.__cmrImportTable = r"{0}\{1}".format(sdeConnFile, self.__cmrImportTable)
            #Set the output gdb
            self.outputGDB = outputGDB

    def __showMsg(self, strMsg):
        """Method for showing messages to prompt and ArcGIS """
        print strMsg
        arcpy.AddMessage(strMsg)

    def __makeTempGdb(self, gdbname):
        """Method for create a new temporary file geodatabase """
        tmpGDB_path = False
        try:
            #Generate path to a temporary workspace
            tmpdir = tempfile.mkdtemp(prefix='cmr_')
            # Process: Create File GDB
            arcpy.CreateFileGDB_management(tmpdir, gdbname, "CURRENT")
            tmpGDB_path = os.path.join(tmpdir, gdbname)
            self.__tmpdirs.append(tmpdir)
            self.__tmpws.append(tmpGDB_path)
            self.tmpGDB = tmpGDB_path
        except Exception, ErrorDesc:
            self.__showMsg(ErrorDesc)
            raise Exception("Failed to create temporary workspace")
        return tmpGDB_path


    def __sdeSqlConnect(self, sdeConnFile):
        """Create database connection"""
        try:
            sdeConn = arcpy.ArcSDESQLExecute(sdeConnFile)
        except Exception, ErrorDesc:
            self.__showMsg(ErrorDesc)
            sdeConn = False
            pass
        return sdeConn


    def __sdeSqlExecute(self, strSQL):
        """Method for executing sql-commands in the sde-databse directly"""
        sdeConn = self.__sdeConn
        try:
            # Pass the SQL statement to the database.
            sdeReturn = sdeConn.execute(strSQL)
        except Exception, ErrorDesc:
            self.__showMsg(ErrorDesc)
            self.__showMsg("ERROR: Problem with method sdeSqlExecute")
            sdeReturn = False
        return sdeReturn

    
    ########################################
    ###          PUBLIC METHODS          ###
    ########################################
    def getStudyId(self):
        return self.__studyId
        
    def initiateStudyArea(self, studyName, hazardDatasetFilepath, elementDatasetFilepath, studyDescription=None, studyId=None):
        """Executes the stored procedure cmrSP_setStudyArea in the cmr database"""
        #Make sure studyName is s string
        if not self.__sdeConn:
            raise Exception('No database connection!')
        if not isinstance(studyName, basestring):
            raise Exception('Failed to initiate the study area, study name must be a string!')
        if not isinstance(hazardDatasetFilepath, basestring):
            raise Exception('Failed to initiate the study area, hazardDataset must be a string!')
        if not isinstance(elementDatasetFilepath, basestring):
            raise Exception('Failed to initiate the study area, elementDataset must be a string!')
        
        #Check if studyId is defined as an integer
        studyId = studyId if isinstance(studyId,int) else "NULL"
        strSQL = self.__sqlExecInitiateStudy.format(studyId, studyName, hazardDatasetFilepath, elementDatasetFilepath, studyDescription)
        #Execute the sql statement 
        sdeReturn = self.__sdeSqlExecute(strSQL)
        # If the return value is a list (a list of lists), display each list as a row
        retVal = False
        if isinstance(sdeReturn, list):
            #study id should be the first field in first row of resultset
            retId = sdeReturn[0][0]
            if retId > 0:
                self.__studyId=retId
                self.__studyName = studyName
                self.__hazardDatasetFilepath = hazardDatasetFilepath
                self.__elementDatasetFilepath = elementDatasetFilepath

                self.__showMsg("Succsessfully initiated study area with id {0}".format(retId))
                retVal = True
            else:
                for row in sdeReturn:
                    print row
                raise Exception('Failed to initiate the study area!')
        else:
            self.__showMsg('Error: sql statement in method initiateStudyArea returned unexpected results.')
            self.__showMsg('Sql: {0}'.format(strSQL))
            raise Exception('Failed to initiate the study area!')
        return retVal


    def prepareInputElements(self, myFeats, myZones, splitFeats):
        "Create a version of the input elements where all lines are clipped at zone boundaries"
        try:
            # Use feature to line with both elements and zones to make sure lines split at boundaries 
            featLine = "feat2line"
            arcpy.FeatureToLine_management("'{0}';'{1}'".format(myFeats,myZones),featLine,"#","ATTRIBUTES")

            # Get all fields of the new layer
            fields = arcpy.ListFields(featLine)
            # Get the cmrFieldMap and keep only the element fields
            keysToKeep = ['element_feature_id'
                          , 'study_id'
                          , 'elementtype_code'
                          , 'route_code'
                          , 'aadt_passenger'
                          , 'aadt_goods'
                          , 'diversion_time']
            cmrFldMap = dict((theKey, self.cmrImportFieldMapping[theKey]) for theKey in keysToKeep)
            # Create a fieldinfo object
            fieldinfo = arcpy.FieldInfo()
            # Iterate through the fields and set those that do not match to HIDDEN
            for field in fields:
                oldName = field.name
                newName = [k for k,v in cmrFldMap.items() if oldName.lower() == v.lower()]
                if len(newName)>0:
                    newName = newName[0]
                    display = "VISIBLE"
                elif field.required or field.type=="Geometry":
                    newName = oldName
                    display = "VISIBLE"
                else:
                    newName = oldName
                    display = "HIDDEN"
                fieldinfo.addField(oldName, newName, display, "")
            #Guess the name of the zone fid
            zoneFid = "FID_{0}".format(os.path.basename(myZones))
            #Make a where clause to keep only those where zonefid = -1 (the element lines)
            strClause = '"{0}" = -1'.format(zoneFid)
            # Create a feature layer with only element lines and element properties
            arcpy.MakeFeatureLayer_management(featLine,splitFeats,strClause,"#",fieldinfo)
            # Make sure it will be deleted upon completion of process (to avoid lock on the tmpGDB)
            self.__tmpgisfiles.append(splitFeats)
            
            return True
        except Exception as e:
            # If an error occurred, print line number and error message
            import traceback, sys
            tb = sys.exc_info()[2]
            strMsg = "Line {0}: {1}".format(tb.tb_lineno, e.args[0])
            raise Exception(strMsg)
        

        

    def hazardElementIntersection(self):
        "Calculate element hazard intersection from the defined hazard and element datasets"
        import time

        studyId = self.__studyId
        #Make study area is initiated
        if not studyId:
            raise Exception("Cannot call hazardElementIntersection method before the study is initiated!")

        cmrImportTable = self.__cmrImportTable
        cmrFldMap = self.cmrImportFieldMapping
        outputGDB = self.outputGDB

        # Before we move on, make sure output geodatabase exist
        if not arcpy.Exists(outputGDB):
            try:
                d, f = os.path.split(outputGDB)
                arcpy.CreateFileGDB_management(d, f, "CURRENT")
            except:
                errMsg = "Output geodatabase {0} does not exist and cannot be created.".format(outputGDB)
                raise Exception(errMsg)
        
        #Create a temporary workspace for geoprocessing
        tmpGDB = self.__makeTempGdb('cmr.gdb')

        myZones = self.__hazardDatasetFilepath
        myFeats = self.__elementDatasetFilepath

        # Layer names to be used within tmpGDB
        splitFeats = 'splitFeats'
        intersectFeats = 'intersectFeats'
        intersectTbl = 'intersectTbl'
        earLyr = 'earLyr'
        tmpImportTable = 'earImportTbl'

        # Name of output element layer
        outEarFeats = self.__earOutputFilename.format(outputGDB, studyId)
        
        try:
            # Get the current workspace
            self.__oldWS = env.workspace
            # Change workspace to our newly created gdb
            env.workspace = tmpGDB
            env.overwriteOutput = True
            env.extent = self.extent


            # Split elements at each zone boundary intersection
            self.__showMsg("Splitting elements at zone-boundary crossings...")
            tic = time.clock()
            self.prepareInputElements(myFeats, myZones, splitFeats)
            self.__showMsg("Processing time: {0}".format(time.clock()-tic))

            #Save the splitted features as the output EAR
            self.__showMsg("Saving elements at risk features to {0}...".format(os.path.basename(outEarFeats)))
            tic = time.clock()
            if arcpy.Exists(outEarFeats):
                #If it exists, delete it
                try:
                    self.__showMsg("Output feature layer {0} already exists: Deleting...".format(os.path.basename(outEarFeats)))
                    arcpy.Delete_management(outEarFeats)
                except:
                    errMsg = "Failed to delete existing output feature layer."
                    raise Exception(errMsg)
            # Finally write the splitFeats layer as a featureclass to outEarFeats
            arcpy.CopyFeatures_management(splitFeats, outEarFeats)
            self.outputFeatures = outEarFeats
            self.__showMsg("Processing time: {0}".format(time.clock()-tic))
            
            #Add field for study_id and element_feature_id
            self.__showMsg("Adding fields to output layer")
            flds = [cmrFldMap['study_id'],cmrFldMap['element_feature_id']]
            vals = ["{0}".format(self.__studyId),"!OBJECTID!"]
            for newFld, newVal in zip(flds, vals):
                arcpy.AddField_management(outEarFeats,newFld,"LONG")
                arcpy.CalculateField_management(outEarFeats,newFld,newVal,"PYTHON","#")


            self.__showMsg("Identifying element hazard intersections...")
            tic = time.clock()
            # Perform intersection returning FID only
            arcpy.Intersect_analysis([outEarFeats, myZones],intersectFeats,"ALL","#","INPUT")
            self.__showMsg("Processing time: {0}".format(time.clock()-tic))

            self.__showMsg("Generating element hazard intersection table...")
            tic = time.clock()
            # Get all fields of the intersected features and identify the fields that contains the fid for the two input features
            fields = arcpy.ListFields(intersectFeats)

            keys = ['hazardzone_feature_id']
            feats = [myZones]
            for key, feat in zip(keys, feats):
                fieldCandidate = "fid_{0}".format(os.path.basename(feat))
                fidField = [s for s in [x.name for x in fields if not x.required] if fieldCandidate.lower() == s.lower()]
                if len(fidField)==1:
                    cmrFldMap[key] = fidField[0]
                else:
                    errMsg = "Could not determine which field that contains the {0}!".format(key)
                    raise Exception(errMsg)
            # Create a fieldinfo object (for table view)
            fieldinfo = arcpy.FieldInfo()
            # Iterate through the fields and define which fields to view and what to call them
            for field in fields:
                oldName = field.name
                newName = [k for k,v in cmrFldMap.items() if oldName.lower() == v.lower()]
                if len(newName)>0:
                    newName = newName[0]
                    display = "VISIBLE"
                else:
                    newName = oldName
                    display = "HIDDEN"
                fieldinfo.addField(oldName, newName, display, "")
            #Define a where clause for eliminating small elements and zero frequency elements
            whereClause = '"{0}" > 0 AND "{1}" > 0'.format(cmrFldMap['element_size'], cmrFldMap['event_frequency'])
            #Create a table view using the defined fieldinfo (renamed and hidden fields)
            arcpy.MakeTableView_management(intersectFeats, intersectTbl, whereClause, tmpGDB, fieldinfo)
            # Make sure it will be deleted upon completion of process (to avoid lock on the tmpGDB)
            self.__tmpgisfiles.append(intersectTbl)
            self.__showMsg("Processing time: {0}".format(time.clock()-tic))
            
            #Append the rows in the intersection table to the import table in the cmr geodatabase
            self.__showMsg("Importing element hazard intersection table to cmr database...")
            tic = time.clock()
            #We must first save the table, then we can append the rows
            arcpy.CopyRows_management(intersectTbl, tmpImportTable)
            arcpy.Append_management(tmpImportTable,cmrImportTable,"NO_TEST")
            #Run the update procedure in sqlserver
            strSQL = self.__sqlExecImportResults.format(studyId)
            sdeReturn = self.__sdeSqlExecute(strSQL)
            retVal = False
            if isinstance(sdeReturn, list):
                maxRetVal = 0
                for row in sdeReturn:
                    maxRetVal = max([maxRetVal,row[0]])
                    self.__showMsg(row[1])
                if maxRetVal==0:
                    retVal = True
            else:
                self.__showMsg("Error: sql statement '{0}' returned unexpected results.".format(strSQL))
                errMsg = "Failed to execute the cmrSP_importResults stored procedure"
                raise Exception(errMsg)
            self.__showMsg("Processing time: {0}".format(time.clock()-tic))
            
            self.__showMsg("Finished geoprocessing!")
            return True
        except Exception as e:
            # If an error occurred, print line number and error message
            import traceback, sys
            tb = sys.exc_info()[2]
            strMsg = "Line {0}: {1}".format(tb.tb_lineno, e.args[0])
            raise Exception(strMsg)



    def cleanup(self):
        try:
            env.workspace = self.__oldWS
            del self.__sdeConn
        except:
            pass
        for f in self.__tmpgisfiles:
            try:
                arcpy.Delete_management(f)
            except:
                pass
        for f in self.__tmpws:
            try:
                arcpy.Delete_management(f)
            except:
                pass
        for f in self.__tmpdirs:
            try:
                os.rmdir(f)
            except:
                pass

