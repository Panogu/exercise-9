// sensing agent

/* Initial beliefs and rules */

// infers whether there is a mission for which goal G has to be achieved by an agent with role R
role_goal(R,G) :- role_mission(R,_,M) & mission_goal(M,G).

// infers whether there the agent has a plan that is relevant for goal G
has_plan_for(G) :- .relevant_plans({+!G},LP) & LP \== [].

// infers whether there is no goal associated with role R for which the agent does not have a relevant plan
i_have_plans_for(R) :- not (role_goal(R,G) & not has_plan_for(G)).

// Witness reputation ratings - loyal agents trust other loyal agents and distrust rogues
// Honest agent's ratings about other agents
witness_reputation(sensing_agent_1, sensing_agent_2, temperature(10), 0.9).
witness_reputation(sensing_agent_1, sensing_agent_3, temperature(10), 0.9).
witness_reputation(sensing_agent_1, sensing_agent_4, temperature(10), 0.9).
witness_reputation(sensing_agent_1, sensing_agent_5, temperature(8), -0.7).
witness_reputation(sensing_agent_1, sensing_agent_6, temperature(8), -0.7).
witness_reputation(sensing_agent_1, sensing_agent_7, temperature(8), -0.7).
witness_reputation(sensing_agent_1, sensing_agent_8, temperature(8), -0.7).
witness_reputation(sensing_agent_1, sensing_agent_9, temperature(-2), -0.9).

/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: greets the user
*/
@start_plan
+!start
    :  true
    <-  .print("Hello world");
    .

/* 
 * Plan for reacting to the addition of the goal !read_temperature
 * Triggering event: addition of goal !read_temperature
 * Context: true (the plan is always applicable)
 * Body: reads the temperature using a weather station artifact and broadcasts the reading
*/
@read_temperature_plan
+!read_temperature
    :  true
    <-  .print("Reading the temperature");
        readCurrentTemperature(47.42, 9.37, Celsius); // reads the current temperature using the artifact
        .print("Read temperature (Celsius): ", Celsius);
        .broadcast(tell, temperature(Celsius)); // broadcasts the temperature reading
    .

/* 
 * Plan for reacting to the addition of the belief organization_deployed(OrgName)
 * Triggering event: addition of belief organization_deployed(OrgName)
 * Context: true (the plan is always applicable)
 * Body: joins the workspace and the organization named OrgName, and creates the goal of adopting relevant roles
*/
@organization_deployed_plan
+organization_deployed(OrgName)
    :  true
    <-  .print("Notified about organization deployment of ", OrgName);
        // joins the workspace
        joinWorkspace(OrgName, _);
        // looks up for, and focuses on the OrgArtifact that represents the organization
        lookupArtifact(OrgName, OrgId);
        focus(OrgId);
        // creates the goal for adopting relevant roles
        !adopt_relevant_roles;
    .

/* 
 * Plan for reacting to the addition of goal !adopt_relevant_roles
 * Triggering event: addition of goal !adopt_relevant_roles
 * Context: true (the plan is always applicable)
 * Body: reasons on the organization specification and adopts all relevant roles
*/
@adopt_relevant_roles_plan
+!adopt_relevant_roles
    :  true
    <-  // finds all relevant roles
        .findall(Role, role(Role, Super) & i_have_plans_for(Role), RelevantRoles);
        .print("Inferred that I have plans for the roles: ", RelevantRoles);
        // adopts each role in the list RelevantRoles (could have also been implemented recursively)
        for (.member(Role, RelevantRoles)) {
            .print("Adopting the role of ", Role);
            adoptRole(Role);
        };
    .

/* 
 * Plan for reacting to the addition of the certified_reputation(CertificationAgent, SourceAgent, MessageContent, CRRating)
 * Triggering event: addition of belief certified_reputation(CertificationAgent, SourceAgent, MessageContent, CRRating)
 * Context: true (the plan is always applicable)
 * Body: prints new certified reputation rating (relevant from Task 3 and on)
*/
+certified_reputation(CertificationAgent, SourceAgent, MessageContent, CRRating)
    :  true
    <-  .print("Certified Reputation Rating: (", CertificationAgent, ", ", SourceAgent, ", ", MessageContent, ", ", CRRating, ")");
    .

/*
 * Plan for reacting to the addition of the witness_reputation(WitnessAgent, TargetAgent, MessageContent, WRRating)
 * Triggering event: addition of belief witness_reputation(WitnessAgent, TargetAgent, MessageContent, WRRating)
 * Context: true (the plan is always applicable)
 * Body: prints new witness reputation rating
*/
+witness_reputation(WitnessAgent, TargetAgent, MessageContent, WRRating)
    :  true
    <-  .print("Witness Reputation Rating: (", WitnessAgent, ", ", TargetAgent, ", ", MessageContent, ", ", WRRating, ")");
    .

/*
 * Plan for responding to requests for certified reputation ratings
 * Triggering event: message asking for certified reputation 
 * Context: the agent is being asked for its certified reputation
 * Body: finds and sends all certified reputation ratings about itself
 */
@reputation_request_plan
+!send_certified_reputation[source(RequestingAgent)]
    :  true
    <-  .print("Reputation request received from ", RequestingAgent);
        // Find all certified reputation ratings about this agent
        .my_name(MyName);
        .findall(
            certified_reputation(CertificationAgent, MyName, MessageContent, CRRating),
            certified_reputation(CertificationAgent, MyName, MessageContent, CRRating),
            Ratings
        );
        
        // Send all found ratings to the requesting agent
        .print("Sending ratings to ", RequestingAgent, ": ", Ratings);
        for (.member(Rating, Ratings)) {
            .send(RequestingAgent, tell, Rating);
        };
        
        // If no ratings were found, inform the requesting agent
        if (.empty(Ratings)) {
            .print("No certified reputation ratings found to send");
            .send(RequestingAgent, tell, no_certified_reputation);
        };
    .

/*
 * Plan for responding to requests for witness reputation ratings
 * Triggering event: request for witness reputation ratings
 * Context: the agent is being asked for witness reputation ratings
 * Body: sends all witness reputation ratings about other agents
 */
+!send_witness_reputation[source(RequestingAgent)]
    :  true
    <-  .print("Witness reputation request received from ", RequestingAgent);
        // Find all witness reputation ratings of this agent about other agents
        .my_name(MyName);
        .findall(
            witness_reputation(MyName, TargetAgent, MessageContent, WRRating),
            witness_reputation(MyName, TargetAgent, MessageContent, WRRating),
            Ratings
        );
        
        // Send all found ratings to the requesting agent
        .print("Sending witness ratings to ", RequestingAgent, ": ", Ratings);
        for (.member(Rating, Ratings)) {
            .send(RequestingAgent, tell, Rating);
        };
        
        // If no ratings were found, inform the requesting agent
        if (.empty(Ratings)) {
            .print("No witness reputation ratings found to send");
            .send(RequestingAgent, tell, no_witness_reputation);
        };
    .

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }

/* Import behavior of agents that react to organizational events
(if observing, i.e. being focused on the appropriate organization artifacts) */
{ include("inc/skills.asl") }