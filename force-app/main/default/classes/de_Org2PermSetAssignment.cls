public with sharing class de_Org2PermSetAssignment {
    private static final String NAMED_CREDENTIAL = 'Target_Org_NC';
    private static final String QUERY_PATH = '/services/data/v66.0/query?q=';
    private static final String PERM_SET_ASSIGN_PATH = '/services/data/v66.0/sobjects/PermissionSetAssignment';

    public class Request {
        @InvocableVariable(required=true description='Username of the user in the target org')
        public String username;

        @InvocableVariable(required=true description='Permission Set Name (API Name) to assign')
        public String permissionSetName;
    }

    public class Response {
        @InvocableVariable
        public Boolean success;

        @InvocableVariable
        public String assignmentId;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(
        label='Assign Permission Set In Target Org'
        description='Assigns a Permission Set to a user in the target org via Named Credential callout.'
    )
    public static List<Response> assignPermissionSets(List<Request> requests) {
        List<Response> results = new List<Response>();
        if (requests == null) {
            return results;
        }
        for (Request req : requests) {
            results.add(assignSingle(req));
        }
        return results;
    }

    private static Response assignSingle(Request req) {
        Response res = new Response();
        if (req == null) {
            res.success = false;
            res.message = 'Request payload is null.';
            return res;
        }

        List<String> missing = new List<String>();
        if (String.isBlank(req.username)) {
            missing.add('username');
        }
        if (String.isBlank(req.permissionSetName)) {
            missing.add('permissionSetName');
        }
        if (!missing.isEmpty()) {
            res.success = false;
            res.message = 'Missing required fields: ' + String.join(missing, ', ');
            return res;
        }

        String userId = resolveUserId(req.username);
        if (String.isBlank(userId)) {
            res.success = false;
            res.message = 'Could not find user with username: ' + req.username;
            return res;
        }

        String permSetId = resolvePermissionSetId(req.permissionSetName);
        if (String.isBlank(permSetId)) {
            res.success = false;
            res.message = 'Could not find permission set with name: ' + req.permissionSetName;
            return res;
        }

        Map<String, Object> payload = new Map<String, Object>();
        payload.put('AssigneeId', userId);
        payload.put('PermissionSetId', permSetId);

        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + NAMED_CREDENTIAL + PERM_SET_ASSIGN_PATH);
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
                res.assignmentId = (String) body.get('id');
                res.message = 'Permission set assigned successfully.';
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

    private static String resolveUserId(String username) {
        String soql = 'SELECT Id FROM User WHERE Username = \'' +
            String.escapeSingleQuotes(username) + '\' LIMIT 1';
        return queryForId(soql);
    }

    private static String resolvePermissionSetId(String permSetName) {
        String soql = 'SELECT Id FROM PermissionSet WHERE Label = \'' +
            String.escapeSingleQuotes(permSetName) + '\' LIMIT 1';
        return queryForId(soql);
    }

    private static String queryForId(String soql) {
        String encodedQuery = EncodingUtil.urlEncode(soql, 'UTF-8');

        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + NAMED_CREDENTIAL + QUERY_PATH + encodedQuery);
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
