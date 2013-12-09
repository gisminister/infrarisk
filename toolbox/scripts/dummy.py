# ---------------------------------------------------------------------------
# dummy.py
# ---------------------------------------------------------------------------
import arcpy
import infrarisk

# Script arguments
pamnames = ['CMR_server'
            ,'CMR_database'
            ,'hazard_zones'
            ,'processtype_id_field'
            ,'event_frequency_field'
            ,'input_elements'
            ,'type_code'
            ,'route_code'
            ,'aadt_passenger'
            ,'aadt_goods'
            ,'diversion_time'
            ,'output_elements']
npams = len(pamnames)
nargs = arcpy.GetArgumentCount()
for n in range(nargs-npams):
    pamnames.append('unknown_%d' % (n+1))

pams = {}    
for n in range(nargs):
    pams[pamnames[n]] = arcpy.GetParameterAsText(n)
    strMsg = '%s: %s' % (pamnames[n], arcpy.GetParameterAsText(n))
    print strMsg
    arcpy.AddMessage(strMsg)

desc = arcpy.Describe(pams['hazard_zones'])
# Find out if the layer represents a feature class
if desc.dataElement.dataType == "FeatureClass":
    pams['hazard_zones'] = desc.nameString
    pams['hazard_zones_path'] = desc.dataElement.catalogPath
else:
    strMsg = "Error: Hazard zones is not a feature class layer"
    arcpy.AddError(strMsg)

desc = arcpy.Describe(pams['input_elements'])
# Find out if the layer represents a feature class
if desc.dataElement.dataType == "FeatureClass":
    pams['input_elements'] = desc.nameString
    pams['input_elements_path'] = desc.dataElement.catalogPath
else:
    strMsg = "Error: Input elements is not a feature class layer"
    arcpy.AddError(strMsg)


try:
    myCMR = cmr.cmr(pams['CMR_server'], pams['CMR_database'])
    #Define a new study area
    myCMR.setStudyArea(studyName='Python testdata', studyDescription='Just for testing data generation from python')

    #Define inputDatasets
    myCMR.addInputDataset(datasetName=pams['hazard_zones'], datasetType='hazard', datasetFilepath=pams['hazard_zones_path'], datasetDescription='Hazard zone dataset')
    myCMR.addInputDataset(datasetName=pams['input_elements'], datasetType='element', datasetFilepath=pams['input_elements_path'], datasetDescription='Element dataset')

    arcpy.AddMessage('\nInput datasets for study area %d' % (myCMR.studyId))
    rows = myCMR.sqlSelect("""SELECT * FROM cmrT_InputDataset WHERE study_id=?""", (myCMR.studyId))
    for row in rows:
        arcpy.AddMessage(', '.join(str(e) for e in row))


except Exception, err:
    arcpy.AddError('ERROR: %s\n' % str(err))
