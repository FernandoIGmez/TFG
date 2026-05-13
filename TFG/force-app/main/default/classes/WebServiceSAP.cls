/**
 * @description       : Web service class for doing DML from SAP Callouts
 * @author            : Fernando Ibarra
 * @group             : 
 * @last modified on  : 09-12-2025
 * @last modified by  : Fernando Ibarra
**/
@RestResource(urlMapping='/WebServiceSAP/*')
global with sharing class WebServiceSAP {

    private static RestRequest request; //Stores the info about the received request
    private static RestResponse response; //Stores the info about the reponse that SAP will receive
    private static String typeOfRecord; //The type of records that we will insert/update/delete in Salesforce
    private static List<Map<String,String>> requestRecords; //The info given in the request body formatted as a list of map of strings (List of "Json" objects)

    /**
    * @description Extract the information of the received HTTP callout into variables.
    * @author Fernando Ibarra | 09-12-2025 
    **/
    private static void fillDefaultVariables(){
        request = RestContext.request;
        response = RestContext.response;
        try {
            //Try to obtain the type of record from the request uri.
            typeOfRecord = request.requestURI.substring(request.requestURI.lastIndexOf('/')+1);
            //Extract the info from the request body and format it as a list of map of strings
            requestRecords = (List<Map<String,String>>)JSON.deserialize(request.requestBody.toString(), List<Map<String,String>>.class);
        } catch (Exception e) {
            //If there are some errors during the mapping of the request data, return an error to the client
            response.statusCode = 404;
            response.responseBody = Blob.valueOf('Bad Request Format');
            throw e;
        }
    }

    /**
    * @description Actions to be done when the callout is a DELETE request (Delete records in Salesforce)
    * @author Fernando Ibarra | 09-12-2025 
    **/
    @HttpDelete
    global static void deleteRecords() {
        try {
            //First, we fill the default variables
            fillDefaultVariables();
            //After decoding the response, upsert the proper records given by the type of record provided in the URI
            switch on typeOfRecord {
                when 'Hotel' {
                    deleteRecords('Account');
                }
                when 'Room' {
                    deleteRecords('Room__c');
                }
                when 'Client' {
                    deleteRecords('Contact');
                }
                when 'Booking' {
                    deleteRecords('Booking__c');
                }
                when else {
                    //If the record type given is not received, launch an error to the client
                    response.statusCode = 404;
                    response.responseBody = Blob.valueOf('Not found');
                    return;
                }
            }
            System.debug(request.requestBody);
            response.statusCode = 200;
        } catch (Exception e) {
            
        }
    }


    /**
    * @description Delete the list of received records in the callout
    * @author Fernando Ibarra | 09-12-2025 
    * @param sObjectName Developer name of the SObject type of objects to be deleted in the callout
    **/
    private static void deleteRecords(String sObjectName){
        try {
            //First, obtain the external ids of the received Records
            List<String> externalIds = new List<String>();
            for (Map<String,String> recordInfo : requestRecords) {
                externalIds.add(recordInfo.get('id'));
            }
            //Do a query in Salesforce using the external Ids
            List<SObject> sObjectsToDelete = Database.query('SELECT Id FROM '+sObjectName+' WHERE ExternalId__c IN :externalIds');
            //Delete the list of records
            List<Database.DeleteResult> results = Database.delete(sObjectsToDelete);
            if(results.isEmpty()){
                //If no records were deleted, add that info to the response body
                response.responseBody = Blob.valueOf('There were no information to delete');
            }
            else{
                //If records were deleted, add that info to the response body
                response.responseBody = Blob.valueOf('Deletion successfully');
            }
        } catch (Exception ex) {
            //If there were any errors during deletion, inform in the response with the description of the exception and a Status code 400
            response.statusCode = 400;
            response.responseBody = Blob.valueOf(ex.getMessage());
            throw ex;
        }
    }

    /**
    * @description Actions to be done when the callout is a PATCH request (Upsert records into Salesforce)
    * @author Fernando Ibarra | 09-12-2025 
    **/
    @HttpPatch
    global static void upsertRecords() {
        try {
            //First, we fill the default variables
            fillDefaultVariables();
            //After decoding the response, upsert the proper records given by the type of record provided in the URI
            switch on typeOfRecord {
                when 'Hotel' {
                    upsertHotels();
                }
                when 'Room' {
                    upsertRooms();
                }
                when 'Client' {
                    upsertClients();
                }
                when 'Booking' {
                    upsertBookings();
                }
                when else {
                    //If the record type given is not received, launch an error to the client
                    response.statusCode = 404;
                    response.responseBody = Blob.valueOf('Not found');
                    return;
                }
            }
            System.debug(request.requestBody);
            response.statusCode = 200;
        } catch (Exception e) {
            
        }
    }

    /**
    * @description Map the information of the received hotels into Salesforce structure and make the upsert of that information
    * @author Fernando Ibarra | 09-12-2025 
    **/
    private static void upsertHotels(){
        List<Account> hotels = new List<Account>();
        for (Map<String,String> recordInfo : requestRecords) {
            Account hotel = new Account();
            hotel.ExternalId__c  = recordInfo.get('id');
            hotel.Name  = recordInfo.get('name');
            hotel.Phone = recordInfo.get('phone');
            hotel.BillingStreet     = recordInfo.get('street');
            hotel.BillingCity       = recordInfo.get('city');
            hotel.BillingState      = recordInfo.get('state');
            hotel.BillingPostalCode = recordInfo.get('postalCode');
            hotel.BillingCountry    = recordInfo.get('country');
            hotels.add(hotel);
        }
        upsertResults(hotels, Account.ExternalId__c);
    }

    /**
    * @description Map the information of the received rooms into Salesforce structure and make the upsert of that information
    * @author Fernando Ibarra | 09-12-2025 
    **/
    private static void upsertRooms(){
        List<Room__c> rooms = new List<Room__c>();
        for (Map<String,String> recordInfo : requestRecords) {
            Room__c room = new Room__c();
            //First we make the relationship with the hotel
            Account relatedHotel = new Account(ExternalId__c = recordInfo.get('hotelId'));
            room.Hotel__r = relatedHotel;
            //After doing the relationship, we fill the rest of the fields
            room.ExternalId__c = recordInfo.get('id');
            room.Name = recordInfo.get('name');
            room.RoomNumber__c = recordInfo.get('name');
            room.Floor__c = Decimal.valueOf(recordInfo.get('floor'));
            room.RoomType__c = recordInfo.get('roomType');
            // room.Occupancy__c = Boolean.valueOf(recordInfo.get('occupancy'));
            room.BedCount__c = Decimal.valueOf(recordInfo.get('bedCount'));
            room.Capacity__c = Decimal.valueOf(recordInfo.get('capacity'));
            room.HasBalcony__c = Boolean.valueOf(recordInfo.get('balcony'));
            room.HasSeaView__c = Boolean.valueOf(recordInfo.get('seaView'));
            room.HasAirConditioning__c = Boolean.valueOf(recordInfo.get('airConditioning'));
            room.HasWifi__c = Boolean.valueOf(recordInfo.get('wifi'));
            room.BasePrice__c = Decimal.valueOf(recordInfo.get('basePrice'));
            rooms.add(room);
        }
        upsertResults(rooms, Room__c.ExternalId__c);
    }

    /**
    * @description Map the information of the received clients into Salesforce structure and make the upsert of that information
    * @author Fernando Ibarra | 09-12-2025 
    **/
    private static void upsertClients(){
        List<Contact> clients = new List<Contact>();
        for (Map<String,String> recordInfo : requestRecords) {
            Contact client = new Contact();
            //After doing the relationship, we fill the rest of the fields
            client.ExternalId__c = recordInfo.get('id');
            client.FirstName = recordInfo.get('fname');
            client.LastName = recordInfo.get('lname');
            client.MobilePhone = recordInfo.get('phone');
            client.Email = recordInfo.get('email');
            clients.add(client);
        }
        upsertResults(clients, Contact.ExternalId__c);
    }

    /**
    * @description Map the information of the received bookings into Salesforce structure and make the upsert of that information
    * @author Fernando Ibarra | 09-12-2025 
    **/
    private static void upsertBookings(){
        List<Booking__c> bookings = new List<Booking__c>();
        for (Map<String,String> recordInfo : requestRecords) {
            Booking__c booking = new Booking__c();
            //First we make the relationship with the room
            Room__c relatedHotel = new Room__c(ExternalId__c = recordInfo.get('roomId'));
            booking.Room__r = relatedHotel;
            //First we make the relationship with the guest
            Contact relatedGuest = new Contact(ExternalId__c = recordInfo.get('clientId'));
            booking.Guest__r = relatedGuest;
            //After doing the relationship, we fill the rest of the fields
            booking.ExternalId__c = recordInfo.get('id');
            booking.ReservationDate__c = Date.valueOf(recordInfo.get('reservationDate'));
            booking.CheckinDate__c = Date.valueOf(recordInfo.get('checkinDate'));
            booking.CheckoutDate__c = Date.valueOf(recordInfo.get('checkoutDate'));
            booking.Status__c = recordInfo.get('status');
            booking.NumberOfGuests__c = Decimal.valueOf(recordInfo.get('guestsNumber'));
            booking.TotalPrice__c = Decimal.valueOf(recordInfo.get('totalPrice'));
            booking.SpecialRequests__c = recordInfo.get('specialRequests');
            bookings.add(booking);
        }
        upsertResults(bookings, Booking__c.ExternalId__c);
    }


    /**
    * @description Auxiliar Method. Make the Upsert DML with the received data propertly mapped. If any error happens during the upsert, inform in the response
    * @author Fernando Ibarra | 09-12-2025 
    * @param sObjectsToUpsert List of Objects to upsert
    * @param fieldName 'External Id' field of the type Objects to upsert
    **/
    private static void upsertResults( List<SObject> sObjectsToUpsert ,Schema.SObjectField fieldName){
        try {
            //Do the upsert DML
            List<Database.UpsertResult> results = Database.upsert(sObjectsToUpsert, fieldName);
            //Fill the response to SAP with the External Id of the record and its Id from Salesforce
            fillResponseWithUpsertDML(sObjectsToUpsert);
        } catch (Exception ex) {
            //If there were any errors during deletion, inform in the response with the description of the exception and a Status code 400
            response.statusCode = 400;
            response.responseBody = Blob.valueOf(ex.getMessage());
            throw ex;
        }
    }

    /**
    * @description Fill the response to SAP with the External Id of the record and its Id from Salesforce
    * @author Fernando Ibarra | 09-12-2025 
    * @param upsertedSObjects 
    **/
    private static void fillResponseWithUpsertDML(List<SObject> upsertedSObjects){
        //Output Example of the body response:
        // {
        //     "CL0000112": "003gL00000LTWRqQAP",
        //     "CL0000111": "003gL00000LTWRpQAP"
        // }
        Map<String,String> responseBodyText = new Map<String,String>();
        for (SObject upsertedObject : upsertedSObjects) {
            responseBodyText.put(upsertedObject.get('ExternalId__c').toString(), upsertedObject.Id);
        }
        response.responseBody = Blob.valueOf(JSON.serialize(responseBodyText));
    }

    // private class ResponseBody{
    //     List<Map<String,String>> data;
    // } 
}