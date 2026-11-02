public with sharing class de_Org2UserProvisioning {
    // Update in org config if you use a different Named Credential label/API name.
    private static final String NAMED_CREDENTIAL = 'Target_Org_NC';
    private static final String USER_CREATE_PATH = '/services/data/v66.0/sobjects/User';
    private static final String PROFILE_QUERY_PATH = '/services/data/v66.0/query?q=';

    public class Request {
        @InvocableVariable(required=true)
        public String firstName;

        @InvocableVariable(required=true)
        public String lastName;

        @InvocableVariable(required=true)
        public String email;

        @InvocableVariable
        public String username;

        @InvocableVariable
        public String alias;

        @InvocableVariable(required=true)
        public String profileName;

        @InvocableVariable
        public String timeZoneSidKey;

        @InvocableVariable
        public String localeSidKey;

        @InvocableVariable
        public String emailEncodingKey;

        @InvocableVariable
        public String languageLocaleKey;
    }

    public class Response {
        @InvocableVariable
        public Boolean success;

        @InvocableVariable
        public String targetUserId;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(
        label='Create User In Target Org'
        description='Creates a Salesforce User in target org via Named Credential callout.'
    )
    public static List<Response> createUsers(List<Request> requests) {
        List<Response> results = new List<Response>();
        if (requests == null) {
            return results;
        }

        for (Request req : requests) {
            results.add(createSingleUser(req));
        }
        return results;
    }

    private static Response createSingleUser(Request req) {
        Response res = new Response();
        if (req == null) {
            res.success = false;
            res.message = 'Request payload is null.';
            return res;
        }

        List<String> missing = new List<String>();
        if (String.isBlank(req.lastName)) {
            missing.add('lastName');
        }
        if (String.isBlank(req.email)) {
            missing.add('email');
        }
        if (String.isBlank(req.profileName)) {
            missing.add('profileName');
        }
        if (!missing.isEmpty()) {
            res.success = false;
            res.message = 'Missing required fields: ' + String.join(missing, ', ');
            return res;
        }

        Map<String, Object> payload = new Map<String, Object>();
        payload.put('FirstName', req.firstName);
        payload.put('LastName', req.lastName);
        payload.put('Email', req.email);
        String resolvedProfileId = resolveProfileId(req.profileName);
        if (String.isBlank(resolvedProfileId)) {
            res.success = false;
            res.message = 'Could not find profile with name: ' + req.profileName;
            return res;
        }
        payload.put('ProfileId', resolvedProfileId);
        payload.put('Username', buildUsername(req.username, req.email));
        payload.put('Alias', buildAlias(req.alias, req.firstName, req.lastName));
        payload.put('TimeZoneSidKey', defaultString(req.timeZoneSidKey, 'America/Los_Angeles'));
        payload.put('LocaleSidKey', defaultString(req.localeSidKey, 'en_US'));
        payload.put('EmailEncodingKey', defaultString(req.emailEncodingKey, 'UTF-8'));
        payload.put('LanguageLocaleKey', defaultString(req.languageLocaleKey, 'en_US'));

        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + NAMED_CREDENTIAL + USER_CREATE_PATH);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(JSON.serialize(payload));

        try {
            HttpResponse response = new Http().send(request);
            Integer statusCode = response.getStatusCode();
            if (statusCode == 201) {
                Map<String, Object> body =
                    (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                res.success = true;
                res.targetUserId = (String) body.get('id');
                res.message = 'User created in target org.';
            } else {
                res.success = false;
                res.message = 'Callout failed. Status: ' + statusCode + ', Body: ' + response.getBody();
            }
        } catch (Exception ex) {
            res.success = false;
            res.message = 'Exception during callout: ' + ex.getMessage();
        }

        return res;
    }

    private static String buildUsername(String username, String email) {
        if (!String.isBlank(username)) {
            return username;
        }
        String seed = String.valueOf(Crypto.getRandomInteger()).replace('-', '');
        return email + '.org2.' + seed.left(6);
    }

    private static String buildAlias(String alias, String firstName, String lastName) {
        if (!String.isBlank(alias)) {
            return alias.length() > 8 ? alias.substring(0, 8) : alias;
        }
        String derived = ((firstName == null ? '' : firstName) + (lastName == null ? '' : lastName));
        derived = derived.replaceAll('[^A-Za-z0-9]', '');
        if (String.isBlank(derived)) {
            derived = 'newuser';
        }
        return derived.length() > 8 ? derived.substring(0, 8) : derived;
    }

    private static String defaultString(String value, String defaultValue) {
        return String.isBlank(value) ? defaultValue : value;
    }

    private static String resolveProfileId(String profileName) {
        String soql = 'SELECT Id FROM Profile WHERE Name = \'' +
            String.escapeSingleQuotes(profileName) + '\' LIMIT 1';
        String encodedQuery = EncodingUtil.urlEncode(soql, 'UTF-8');

        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + NAMED_CREDENTIAL + PROFILE_QUERY_PATH + encodedQuery);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');

        try {
            HttpResponse response = new Http().send(request);
            if (response.getStatusCode() != 200) {
                return null;
            }

            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            List<Object> records = (List<Object>) body.get('records');
            if (records == null || records.isEmpty()) {
                return null;
            }

            Map<String, Object> firstRecord = (Map<String, Object>) records[0];
            return (String) firstRecord.get('Id');
        } catch (Exception ex) {
            return null;
        }
    }
}
