// acting agent

/* Initial beliefs and rules */

// The agent has a belief about the location of the W3C Web of Thing (WoT) Thing Description (TD)
// that describes a Thing of type https://ci.mines-stetienne.fr/kg/ontology#PhantomX
robot_td("https://raw.githubusercontent.com/Interactions-HSG/example-tds/main/tds/leubot1.ttl").

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
 * Plan for reacting to the addition of the belief organization_deployed(OrgName)
 * Triggering event: addition of belief organization_deployed(OrgName)
 * Context: true (the plan is always applicable)
 * Body: joins the workspace and the organization named OrgName
*/
@organization_deployed_plan
+organization_deployed(OrgName)
    :  true
    <-  .print("Notified about organization deployment of ", OrgName);
        // joins the workspace
        joinWorkspace(OrgName);
        // looks up for, and focuses on the OrgArtifact that represents the organization
        lookupArtifact(OrgName, OrgId);
        focus(OrgId);
    .

/* 
 * Plan for reacting to the addition of the belief available_role(Role)
 * Triggering event: addition of belief available_role(Role)
 * Context: true (the plan is always applicable)
 * Body: adopts the role Role
*/
@available_role_plan
+available_role(Role)
    :  true
    <-  .print("Adopting the role of ", Role);
        adoptRole(Role);
    .

/* 
 * Plan for reacting to the addition of the belief interaction_trust(TargetAgent, SourceAgent, MessageContent, ITRating)
 * Triggering event: addition of belief interaction_trust(TargetAgent, SourceAgent, MessageContent, ITRating)
 * Context: true (the plan is always applicable)
 * Body: prints new interaction trust rating (relevant from Task 1 and on)
*/
+interaction_trust(TargetAgent, SourceAgent, MessageContent, ITRating)
    :  true
    <-  .print("Interaction Trust Rating: (", TargetAgent, ", ", SourceAgent, ", ", MessageContent, ", ", ITRating, ")");
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
 * Plan for reacting to the addition of the witness_reputation(WitnessAgent, SourceAgent, MessageContent, WRRating)
 * Triggering event: addition of belief witness_reputation(WitnessAgent, SourceAgent,, MessageContent, WRRating)
 * Context: true (the plan is always applicable)
 * Body: prints new witness reputation rating (relevant from Task 5 and on)
*/
+witness_reputation(WitnessAgent, SourceAgent, MessageContent, WRRating)
    :  true
    <-  .print("Witness Reputation Rating: (", WitnessAgent, ", ", SourceAgent, ", ", MessageContent, ", ", WRRating, ")");
    .

/* 
 * Plan for reacting to the addition of the goal !select_reading(TempReadings, Celsius)
 * Triggering event: addition of goal !select_reading(TempReadings, Celsius)
 * Context: true (the plan is always applicable)
 * Body: selects the temperature reading from the agent with the highest average trust rating
*/
@select_reading_task_1_plan
+!select_reading(TempReadings, Celsius)
    :  true
    <-  // Collect all agent-temperature pairs
        .findall([Agent, Temp], temperature(Temp)[source(Agent)], AgentTemps);
        
        // Create a list to store agent-temperature-trust triplets
        .findall(
            [AvgTrust, Agent, Temp],
            (
                .member([Agent, Temp], AgentTemps) &
                .findall(Rating, interaction_trust(acting_agent, Agent, _, Rating), Ratings) &
                .length(Ratings, Len) &
                Len > 0 &
                Sum = math.sum(Ratings) &
                AvgTrust = Sum / Len &
                .print("Agent ", Agent, " has average trust: ", AvgTrust, " (from ", Len, " ratings)")
            ),
            TrustTempList
        );
        
        // Check if we have any trusted agents
        if (.length(TrustTempList, ListLen) & ListLen > 0) {
            // Sort the list by trust rating (descending)
            .sort(TrustTempList, SortedList);
            .reverse(SortedList, ReversedList);
            
            // Get the first element (highest trust)
            .nth(0, ReversedList, [BestTrust, BestAgent, BestTemp]);
            
            .print("Most trusted agent is ", BestAgent, " with average trust ", BestTrust);
            Celsius = BestTemp;
        } else {
            // Fallback if no trust ratings available
            .print("No trusted agents found, selecting first temperature");
            .nth(0, TempReadings, Celsius);
        }
    .

/* 
 * Plan for reacting to the addition of the goal !manifest_temperature
 * Triggering event: addition of goal !manifest_temperature
 * Context: the agent believes that a WoT TD of an onto:PhantomX is located at Location
 * Body: collects temperatures, selects the one from most trusted agent, and manifests it
*/
@manifest_temperature_plan 
+!manifest_temperature
    :  robot_td(Location)
    <-  // Collect all temperature readings
        .findall(Temp, temperature(Temp)[source(_)], TempReadings);
        .print("Collected temperature readings: ", TempReadings);
        
        if (.length(TempReadings, Len) & Len > 0) {
            // Use the select_reading plan to pick the temperature from the most trusted agent
            !select_reading(TempReadings, SelectedTemp);
            .print("I will manifest the temperature: ", SelectedTemp);
            
            convert(SelectedTemp, -20.00, 20.00, 200.00, 830.00, Degrees)[artifact_id(ConverterId)]; 
            .print("Temperature Manifesting (moving robotic arm to): ", Degrees);
            
            // creates a ThingArtifact based on the TD of the robotic arm
            makeArtifact("leubot1", "org.hyperagents.jacamo.artifacts.wot.ThingArtifact", [Location, true], Leubot1Id); 
            
            // sets the API key for controlling the robotic arm as an authenticated user
            //setAPIKey("77d7a2250abbdb59c6f6324bf1dcddb5")[artifact_id(Leubot1Id)];
            
            // invokes the action onto:SetWristAngle for manifesting the temperature
            invokeAction("https://ci.mines-stetienne.fr/kg/ontology#SetWristAngle", ["https://www.w3.org/2019/wot/json-schema#IntegerSchema"], [Degrees])[artifact_id(Leubot1Id)];
        } else {
            .print("No temperature readings available yet. Waiting for readings...");
            .wait(1000); // Wait a bit and try again
            !manifest_temperature;
        }
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

/* Import interaction trust ratings */
{ include("inc/interaction_trust_ratings.asl") }