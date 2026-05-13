/**
 * @description       : Apex class that makes the API callout to DEEPL in order to translate the description of the request into spanish
 * @author            : Fernando Ibarra
 * @group             : 
 * @last modified on  : 03-04-2026
 * @last modified by  : Fernando Ibarra
**/
public without sharing class TranslationApiCallout {

    /**
    * @description Makes the API callout with all the descriptions if all selected requests. After receiving the translations, updates each case with the translated description. 
    * @author Fernando Ibarra | 03-04-2026 
    * @param casesIdsToTranslate 
    **/
    @Future(callout=true)
    public static void makeCallout(Set<Id> casesIdsToTranslate){
        List<Case> casesToTranslate = [SELECT Id, Description FROM Case WHERE Id IN: casesIdsToTranslate];
        
        List<String> textsToTranslate = new List<String>();
        for (Case actualCase : casesToTranslate) {
            textsToTranslate.add(actualCase.Description);
        }

        String jsonBodyResponse = makeCallout(textsToTranslate);
        BodyResponse formattedResponse = (BodyResponse) JSON.deserializeStrict(jsonBodyResponse, BodyResponse.class);
        
        if(formattedResponse.translations == null || formattedResponse.translations.isEmpty()) return;

        List<Case> updatedCases = new List<Case>();
        for (Integer i = 0; i < casesToTranslate.size(); i++) {
            Case c = casesToTranslate.get(i);
            Translation caseTranslation = formattedResponse.translations.get(i);
            updatedCases.add(new Case(Id = c.Id, TranslatedDescription__c = caseTranslation.text));
        }

        if(updatedCases.isEmpty()) return;

        update updatedCases;
    }

    
    /**
    * @description Prepare the data and make the HTTP callout to the API that translate the descriptions.
    * @author Fernando Ibarra | 03-04-2026 
    * @param textsToTranslate 
    * @return String 
    **/
    public static String makeCallout(List<String> textsToTranslate){
        //First, exit this method if no text were provide to translate
        if(textsToTranslate == null || textsToTranslate.isEmpty()) return null;
        // Instantiate a new Http object
        Http h = new Http();

        // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api-free.deepl.com'+'/v2/translate');
        req.setMethod('POST');
        req.setHeader('Authorization', 'DeepL-Auth-Key 831d45b4-757f-494b-8606-edb3acdc3e01:fx');
        req.setHeader('Content-Type', 'application/json');
        
        // String bodyStructure = '{"text":["'+textToTranslate+'"],"target_lang":"ES"}';
        BodyRequest bodyReq = new BodyRequest(null);
        for (String textToTranslate : textsToTranslate) {
            bodyReq.addTextToBody(textToTranslate);
        }
        
        System.debug('bodyReq');
        System.debug(bodyReq);
        System.debug(JSON.serialize(bodyReq));
        req.setBody(JSON.serialize(bodyReq));

        // Send the request, and return a response
        HttpResponse res = h.send(req);
        System.debug('RESPUESTA');
        System.debug(res.getBody());
        return res.getBody();
    }


    public class BodyRequest{
        
        private List<String> text;
        private String target_lang;

        public BodyRequest(String target_lang){
            this.target_lang = target_lang == null ? 'ES' : target_lang;
            text = new List<String>(); 
        }

        public void addTextToBody(String textToAdd){
            text.add(textToAdd);
        }

    }

    public class BodyResponse{
        public List<Translation> translations;
        public BodyResponse(){

        }
        
    }

    public class Translation{
        public String detected_source_language;
        public String text;
        public Translation(){

        }

    }
}