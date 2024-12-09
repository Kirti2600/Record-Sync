@RestResource(urlMapping='/RecordSync/*') 
global with sharing class RecordSyncController {
  
    @HttpPost 
     global static String receiveRecords(String objectName, String jsonRecords) 
    {
       try {
            // Deserialize the JSON string into a list of sObjects
            List<sObject> records = (List<sObject>) JSON.deserialize(jsonRecords, List<sObject>.class);
			system.debug('records -->'+records);
            if (!records.isEmpty()) {
                // Loop through each record 
                for (sObject record : records) {
                    record.Id = null;
                    record.put('OwnerId', UserInfo.getUserId());  //Replace with the ID of the currently logged-in user.
                }

               Database.insert(records);
                return 'Success: Records inserted successfully.';
            } else {
                return 'Error: No records provided.';
            }
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }
}