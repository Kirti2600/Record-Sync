@RestResource(urlMapping='/RecordSyncUpdate/*')
global with sharing class RecordSyncUpdateController {
    @HttpPost
    global static String receiveUpdatedRecords(String objectName, String jsonRecords) {
       try {
            System.debug('Received records in target org: ' + jsonRecords);
            
            // Deserialize the JSON string into a List of Objects (generic deserialization)
            List<Object> rawParsed = (List<Object>) JSON.deserializeUntyped(jsonRecords);
            System.debug('Deserialized Object: ' + rawParsed);

            if (rawParsed == null || rawParsed.isEmpty()) {
                return 'Error: No records provided in the request.';
            }

            List<sObject> updatedRecords = new List<sObject>();
            
              // Get the current user's ID to update the OwnerId field
            String currentUserId = UserInfo.getUserId();

            // Loop through each object and process it
            for (Object obj : rawParsed) {
                
                if (obj instanceof Map<String, Object>) {
                    Map<String, Object> recordMap = (Map<String, Object>) obj;

                    // Check if the recordMap is not null and contains 'External_ID__c'
                    if (recordMap != null && recordMap.containsKey('External_ID__c')) {
                        String externalId = String.valueOf(recordMap.get('External_ID__c'));

                        if (String.isBlank(externalId)) {
                            System.debug('Skipping record without External_ID__c.');
                            continue;
                        }

                        // Query the existing record using the External_ID__c
                        String query = 'SELECT Id, External_ID__c FROM ' + String.escapeSingleQuotes(objectName) + ' WHERE External_ID__c = :externalId LIMIT 1';
                        List<sObject> existingRecords = Database.query(query);

                        if (!existingRecords.isEmpty()) {
                            sObject recordToUpdate = existingRecords[0]; // Take the first record found
                             // Set the OwnerId to the current user
                            recordToUpdate.put('OwnerId', currentUserId);

                            

                            // Describe the object to get metadata for field editability
                            Schema.DescribeSObjectResult describeResult = recordToUpdate.getSObjectType().getDescribe();
                            Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();

                            // Loop through the fields in the recordMap and update only editable fields
                            for (String field : recordMap.keySet()) {
                                
                                // Log field name before processing
                                  System.debug('Processing field: ' + field);
                                
                                if (field == 'attributes' || field == 'ownerId') {
                                        continue;
                                       }
                                
                                // Check if the field is editable and valid
                                if (field != 'External_ID__c' && field != 'LastModifiedById' && field != 'CreatedDate' &&
                                    field != 'LastModifiedDate' && field != 'CreatedById' && recordMap.get(field) != null) {

                                    // Ensure the field exists in the object schema
                                    if (fieldMap.containsKey(field)) {
                                        Schema.SObjectField fieldToken = fieldMap.get(field);
                                        Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();

                                        // Only update the field if it is editable
                                        if (fieldDescribe.isUpdateable()) {
                                            Object fieldValue = recordMap.get(field);
                                            
                                             // Log field value for debugging
                                         System.debug('Updating field: ' + field + ' with value: ' + fieldValue);


                                            // Handle type conversion based on the field type
                                            if (fieldDescribe.getType() == Schema.DisplayType.Date) {
                                                // Convert String to Date if it's a Date field
                                                if (fieldValue instanceof String) {
                                                    try {
                                                        fieldValue = Date.valueOf((String) fieldValue);  // Convert String to Date
                                                    } catch (Exception e) {
                                                        System.debug('Error converting String to Date for field ' + field + ': ' + e.getMessage());
                                                    }
                                                }
                                            } else if (fieldDescribe.getType() == Schema.DisplayType.DateTime) {
                                                // Convert String to DateTime if it's a DateTime field
                                                if (fieldValue instanceof String) {
                                                    try {
                                                        fieldValue = DateTime.valueOf((String) fieldValue);  // Convert String to DateTime
                                                    } catch (Exception e) {
                                                        System.debug('Error converting String to DateTime for field ' + field + ': ' + e.getMessage());
                                                    }
                                                }
                                            }

                                            // Only update the field if the type conversion is successful
                                            if (fieldValue != null) {
                                                recordToUpdate.put(field, fieldValue);
                                            } else {
                                                System.debug('Skipping field ' + field + ' due to invalid type conversion.');
                                            }
                                        }
                                    } else {
                                        System.debug('Field ' + field + ' does not exist on object ' + objectName);
                                    }
                                }
                            }
                            updatedRecords.add(recordToUpdate);
                        } else {
                            System.debug('No record found with External_ID__c: ' + externalId);
                        }
                    } else {
                        System.debug('Skipping invalid record (missing External_ID__c): ' + obj);
                    }
                } else {
                    System.debug('Skipping invalid object (not a Map<String, Object>): ' + obj);
                }
            }

            if (!updatedRecords.isEmpty()) {
                // Update the records in Salesforce
                update updatedRecords;
                return 'Success: Records updated successfully.';
            } else {
                return 'Error: No records were updated.';
            }

        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }  
     
        
}