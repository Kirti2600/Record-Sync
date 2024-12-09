@RestResource(urlMapping='/RecordSyncUndelete/*')
global with sharing class RecordSyncUndeleteController {
    @HttpPost
    global static String undeleteRecords(String objectName, String idsToUndelete) { 
        try {
            System.debug('Undelete request received for object: ' + objectName + ', IDs: ' + idsToUndelete);

            // Deserialize the list of IDs
            List<String> ids = (List<String>) JSON.deserialize(idsToUndelete, List<String>.class);

            if (ids.isEmpty()) {
                return 'Error: No IDs provided for undelete.';
            }

            // Query the records based on the External_ID__c field and ensure deleted records are included
            String query = 'SELECT Id FROM ' + String.escapeSingleQuotes(objectName) + ' WHERE External_ID__c IN :ids AND IsDeleted = TRUE ALL ROWS';
            List<sObject> recordsToUndelete = Database.query(query);
            
            if (!recordsToUndelete.isEmpty()) {
                // Undelete the records
                Database.undelete(recordsToUndelete);
                return 'Success: Records undeleted successfully.';
            } else {
                return 'Error: No matching deleted records found for the given External_ID__c.';
            }
        } catch (Exception e) {
            System.debug('Exception during undelete: ' + e.getMessage());
            return 'Error: ' + e.getMessage();
        }
    }
}