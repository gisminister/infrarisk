import sys, os, arcpy
from arcpy import mapping
from infrarisk import cmrstudy


def getInputPams(pamnames):
    npams = len(pamnames)
    nargs = arcpy.GetArgumentCount()
    for n in range(nargs-npams):
        pamnames.append('unknown_%d' % (n+1))
    pams = {}    
    for n in range(nargs):
        pams[pamnames[n]] = arcpy.GetParameterAsText(n)
    return pams
        
def validatePams(pams):
    retval = True
    desc = arcpy.Describe(pams['hazard_zones'])
    # Find out if the layer represents a feature class
    if desc.dataElement.dataType == "FeatureClass":
        pams['hazard_zones'] = desc.nameString
        pams['hazard_zones_path'] = desc.dataElement.catalogPath
    else:
        strMsg = "Error: Hazard zones is not a feature class layer"
        arcpy.AddError(strMsg)
        retval = False

    desc = arcpy.Describe(pams['input_elements'])
    # Find out if the layer represents a feature class
    if desc.dataElement.dataType == "FeatureClass":
        pams['input_elements'] = desc.nameString
        pams['input_elements_path'] = desc.dataElement.catalogPath
    else:
        strMsg = "Error: Input elements is not a feature class layer"
        arcpy.AddError(strMsg)
        retval = False
    return retval


if __name__ == '__main__':
    try:
        pamnames = ['sdeConnFile'
                    ,'studyId'
                    ,'studyName'
                    ,'studyDescription'
                    ,'hazard_zones'
                    ,'processtype_id'
                    ,'event_frequency'
                    ,'input_elements'
                    ,'elementtype_code'
                    ,'route_code'
                    ,'aadt_passenger'
                    ,'aadt_goods'
                    ,'diversion_time'
                    ,'outputGDB']

        pams = getInputPams(pamnames)
        if not validatePams(pams):
            raise Exception('Exit function!')

        #Create an instance of the cmr class
        sdeConnFile = pams['sdeConnFile']
        try:
            studyId = int(pams['studyId'])
        except:
            studyId = None
        studyName = pams['studyName']
        studyDescription =  pams['studyDescription']
        hazardDatasetFilepath = pams['hazard_zones_path']
        elementDatasetFilepath = pams['input_elements_path']
        outputGDB = pams['outputGDB']

        #Create the cmrstudy object
        myStudy = cmrstudy(sdeConnFile, outputGDB)
        try:
            #Set define input fields in fieldmapping
            myStudy.cmrImportFieldMapping['processtype_id'] = pams['processtype_id']
            myStudy.cmrImportFieldMapping['event_frequency'] = pams['event_frequency']
            myStudy.cmrImportFieldMapping['elementtype_code'] = pams['elementtype_code']
            myStudy.cmrImportFieldMapping['route_code'] = pams['route_code']
            myStudy.cmrImportFieldMapping['aadt_passenger'] = pams['aadt_passenger']
            myStudy.cmrImportFieldMapping['aadt_goods'] = pams['aadt_goods']
            myStudy.cmrImportFieldMapping['diversion_time'] = pams['diversion_time']
            #Initiate the study area
            myStudy.initiateStudyArea(studyName=studyName, studyId=studyId, studyDescription=studyDescription)
            #Define input hazard data
            datasetType = 'hazard'
            myStudy.addInputDataset(datasetType, hazardDatasetFilepath)
            #Define input element data
            datasetType = 'element'
            myStudy.addInputDataset(datasetType, elementDatasetFilepath)
            #Apply the geoprocessing
            if myStudy.hazardElementIntersection():
                studyId = myStudy.getStudyId()
                templateDir = os.path.dirname(os.path.realpath(__file__))
                templateDir = os.path.abspath(os.path.join(templateDir, os.path.pardir, 'templates'))
                
                mxd = mapping.MapDocument("CURRENT")
                df = mapping.ListDataFrames(mxd)[0]
                lyrName = "ear_{0}".format(studyId)
                arcpy.MakeFeatureLayer_management(myStudy.outputFeatures,lyrName)
                arcpy.ApplySymbologyFromLayer_management(lyrName, r"{0}\ear.lyr".format(templateDir))
                lyrFile = mapping.Layer(lyrName)
                mapping.AddLayer(df, lyrFile)

                arcpy.RefreshTOC()
                arcpy.RefreshActiveView()

                q_src = "{0}\cmrV_ElementValueDamages".format(sdeConnFile)
                q_dest = "ear_{0}_damages".format(studyId)
                q_cond = "study_id = {0}".format(studyId)
                q_keyflds = "element_feature_id, hazardzone_feature_id"
                arcpy.MakeQueryTable_management('"{0}"'.format(q_src),'"{0}"'.format(q_dest),"USE_KEY_FIELDS","#","#",q_cond)
            else:
                arcpy.AddError("Geoprocessing failed!")
        except Exception, err:
            sys.stderr.write('ERROR: {0}\n'.format(err))
            arcpy.AddError('ERROR: {0}\n'.format(err))
        finally:
            print "Cleaning up..."
            myStudy.cleanup()
    except Exception, err:
        arcpy.AddError('ERROR: {0}\n'.format(err))


