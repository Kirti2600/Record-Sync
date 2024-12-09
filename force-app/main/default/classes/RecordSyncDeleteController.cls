@RestResource(urlMapping='/RecordSyncDelete/*')
global with sharing class RecordSyncDeleteController {
    @HttpPost
      global static String deleteRecords(String objectName, String idsToDelete) { 
       try {
            System.debug('Delete request received for object: ' + objectName + ', IDs: ' + idsToDelete);

            // Deserialize the list of IDs
            List<String> ids = (List<String>) JSON.deserialize(idsToDelete, List<String>.class);

            if (ids.isEmpty()) {
                return 'Error: No IDs provided for deletion.';
            }

            // Query the records based on the External_ID__c field
            String query = 'SELECT Id FROM ' + String.escapeSingleQuotes(objectName) + ' WHERE External_ID__c IN :ids';
            List<sObject> recordsToDelete = Database.query(query);

            if (!recordsToDelete.isEmpty()) {
                Database.delete(recordsToDelete);
                return 'Success: Records deleted successfully.';
            } else {
                return 'Error: No matching records found for the given External_ID__c.';
            }
        } catch (Exception e) {
            System.debug('Exception during delete: ' + e.getMessage());
            return 'Error: ' + e.getMessage();
        }
    }

}