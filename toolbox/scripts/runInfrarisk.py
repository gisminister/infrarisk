import arcpy
import sys
from infrarisk import cmrstudy


if __name__=='__main__':
    #Create an instance of the cmr class
    studyName = 'Testdata'
    sdeConnFile = r'Database Connections\cmrGeo@localhost.sde'
    outputGDB = r"\\wii\OfflineFolders\baardr\Documents\cicero\projects\infrarisk\risk_model\example_data\cmrResults.gdb"
    
    studyDescription = 'Example study in Otta'
    hazardDatasetFilepath = r'\\wii\OfflineFolders\baardr\Documents\cicero\projects\infrarisk\risk_model\example_data\example_data.mdb\hazard_zones'
    hazardDatasetDescription='Hazard map from Otta with rock falls, debris flows and flood zones'
    elementDatasetFilepath = r'\\wii\OfflineFolders\baardr\Documents\cicero\projects\infrarisk\risk_model\example_data\example_data.mdb\roads'
    elementDatasetDescription='Road map from Otta'
        
    #Create the cmrstudy object
    myStudy = cmrstudy(sdeConnFile, outputGDB)
    try:
        #Initiate the study area
        myStudy.initiateStudyArea(studyName=studyName, studyDescription=studyDescription)
        #Define input hazard data
        datasetType = 'hazard'
        myStudy.addInputDataset(datasetType
                                     , hazardDatasetFilepath
                                     , hazardDatasetDescription)
        #Define input element data
        datasetType = 'element'
        myStudy.addInputDataset(datasetType
                                     , elementDatasetFilepath
                                     , elementDatasetDescription)
        #Apply the geoprocessing
        if myStudy.hazardElementIntersection():
            print "Ready to define query tables"
        else:
            print "Geoprocessing failed!"
    except Exception, err:
        sys.stderr.write('ERROR: {0}\n'.format(err))
        arcpy.AddError('ERROR: {0}\n'.format(err))
    finally:
        print "Cleaning up..."
        myStudy.cleanup()

