/**
 * @description       : Controller used in the Digital Experience web page that clients access via URL. We use without sharing because the guest user that clients use have no permissions for most of the functionallities done in this class.
 * @author            : Fernando Ibarra
 * @group             : 
 * @last modified on  : 03-04-2026
 * @last modified by  : Fernando Ibarra
**/
public without sharing class ClientsPageController {

    /**
    * @description Returns true if the given booking by its UUID Exist. If not, throw an exception
    * @author Fernando Ibarra | 03-04-2026 
    * @param bookingId UUID of the Booking
    * @return Boolean 
    **/
    @AuraEnabled
    public static Boolean validateBooking(String bookingId){
        Booking__c booking = [SELECT Id FROM Booking__c WHERE UUID__c =: bookingId];
        if(booking == null) throw new AuraHandledException('Ex');
        return true; 
    }

    /**
    * @description Obtains all the Requests linked to a specific booking. We use the UUID field to do this query.
    * @author Fernando Ibarra | 03-04-2026 
    * @param bookingId UUID of the Booking
    * @return List<Case> Requests linked to the Booking
    **/
    @AuraEnabled
    public static List<Case> getCasesInfo(String bookingId){
        if(String.isBlank(bookingId)) throw new AuraHandledException('Ex');
        return [SELECT Id, CaseNumber, Description, Subject, Status, Category__c, Priority, CreatedDate FROM Case WHERE BookingId__r.UUID__c =: bookingId AND BookingId__r.CheckIn__c = TRUE ORDER BY CreatedDate DESC];
    }


    
    /**
    * @description Obtains all the info of a specific Request via its Id
    * @author Fernando Ibarra | 03-04-2026 
    * @param caseId 
    * @return Case 
    **/
    @AuraEnabled
    public static Case getCaseInfo(Id caseId){
        return [SELECT Id, CaseNumber, Description, Subject, Status, Category__c, Priority, CreatedDate FROM Case WHERE Id =: caseId LIMIT 1];
    }

    /**
    * @description Create a new Request for a specific booking. 
    * @author Fernando Ibarra | 03-04-2026 
    * @param bookingId 
    * @return Case 
    **/
    @AuraEnabled
    public static Case createNewCase(String bookingId){
        Booking__c booking = [SELECT Id, Guest__c FROM Booking__c WHERE UUID__c =: bookingId ];
        Case newCase = new Case();
        newCase.BookingId__c = booking.Id;
        newCase.Status = 'New';
        newCase.Origin = 'Web';
        newCase.ContactId = booking.Guest__c;
        insert newCase;
        return getCaseInfo(newCase.Id);
    }


    /**
    * @description Obtains the picklist values of a specific field of the Request object
    * @author Fernando Ibarra | 03-04-2026 
    * @param fieldName 
    * @return List<Map<String, String>> 
    **/
    @AuraEnabled
    public static List<Map<String,String>> getPicklistValues(String fieldName){
        List<Map<String,String>> picklist = new List<Map<String,String>>();
        List<Schema.PicklistEntry> ple = Schema.getGlobalDescribe().get('Case').getDescribe().fields.getMap().get(fieldName).getDescribe().getPicklistValues() ;

        for (Schema.PicklistEntry entry : ple) {
            picklist.add( new Map<String, String>{ 'label' => entry.getLabel() , 'value' => entry.getValue()});
            
        }
        return picklist;
    }

    /**
    * @description Updates a single case
    * @author Fernando Ibarra | 03-04-2026 
    * @param caseToUpdate 
    **/
    @AuraEnabled
    public static void updateCase(Case caseToUpdate){
        update caseToUpdate;
    }

    /**
    * @description Moves a case to In Progress
    * @author Fernando Ibarra | 03-04-2026 
    * @param caseId 
    **/
    @AuraEnabled
    public static void moveCaseToInProgress(Id caseId){
        update new Case( Id = caseId, Status = 'InProgress');
    }

}