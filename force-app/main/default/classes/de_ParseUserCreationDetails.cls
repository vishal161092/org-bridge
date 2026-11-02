public with sharing class de_ParseUserCreationDetails {

    public class Request {
        @InvocableVariable(required=true description='The User_Creation_Details__c field value from ServiceRequest')
        public String userCreationDetails;
    }

    public class Response {
        @InvocableVariable
        public String firstName;

        @InvocableVariable
        public String lastName;

        @InvocableVariable
        public String email;

        @InvocableVariable
        public String profileName;

        @InvocableVariable
        public String username;

        @InvocableVariable
        public String permissionSetName;
    }

    @InvocableMethod(
        label='Parse User Creation Details'
        description='Parses First Name, Last Name, and Email from the User_Creation_Details__c text field.'
    )
    public static List<Response> parse(List<Request> requests) {
        List<Response> results = new List<Response>();
        for (Request req : requests) {
            results.add(parseSingle(req));
        }
        return results;
    }

    private static Response parseSingle(Request req) {
        Response res = new Response();
        if (req == null || String.isBlank(req.userCreationDetails)) {
            return res;
        }

        for (String line : req.userCreationDetails.split('\n')) {
            line = line.trim();
            if (String.isBlank(line)) {
                continue;
            }
            Integer dashIndex = line.indexOf('-');
            if (dashIndex < 0) {
                continue;
            }
            String key = line.substring(0, dashIndex).trim().toLowerCase();
            String value = line.substring(dashIndex + 1).trim();

            if (key == 'first name') {
                res.firstName = value;
            } else if (key == 'last name') {
                res.lastName = value;
            } else if (key == 'email') {
                res.email = value;
            } else if (key == 'profile name') {
                res.profileName = value;
            } else if (key == 'username') {
                res.username = value;
            } else if (key == 'permission set name') {
                res.permissionSetName = value;
            }
        }
        return res;
    }
}
