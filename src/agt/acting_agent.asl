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
 * Triggering event: addition of belief witness_reputation(WitnessAgent, SourceAgent, MessageContent, WRRating)
 * Context: true (the plan is always applicable)
 * Body: prints new witness reputation rating (relevant from Task 4 and on)
*/
+witness_reputation(WitnessAgent, SourceAgent, MessageContent, WRRating)
    :  true
    <-  .print("Witness Reputation Rating: (", WitnessAgent, ", ", SourceAgent, ", ", MessageContent, ", ", WRRating, ")");
    .

/*
 * Plan for requesting certified reputation ratings from temperature readers
 * Triggering event: addition of goal !request_certified_reputation
 * Context: true (the plan is always applicable)
 * Body: finds all agents with temperature readings and asks them for their certified reputation
 */
+!request_certified_reputation
    :  true
    <-  .print("Requesting certified reputation from temperature readers");
        // Find all agents who have submitted temperature readings
        .findall(Agent, temperature(_)[source(Agent)], TempAgents);
        .print("Temperature readers: ", TempAgents);
        
        // Request certified reputation from each agent
        for (.member(Agent, TempAgents)) {
            .print("Requesting certified reputation from ", Agent);
            .send(Agent, achieve, send_certified_reputation);
        };
        
        // Wait a moment for responses to arrive
        .wait(1000);
    .

/*
 * Plan for requesting witness reputation ratings from temperature readers
 * Triggering event: addition of goal !request_witness_reputation
 * Context: true (the plan is always applicable)
 * Body: finds all agents with temperature readings and asks them for their witness reputation ratings
 */
+!request_witness_reputation
    :  true
    <-  .print("Requesting witness reputation from temperature readers");
        // Find all agents who have submitted temperature readings
        .findall(Agent, temperature(_)[source(Agent)], TempAgents);
        .print("Temperature readers: ", TempAgents);
        
        // Request witness reputation from each agent
        for (.member(Agent, TempAgents)) {
            .print("Requesting witness reputation from ", Agent);
            .send(Agent, achieve, send_witness_reputation);
        };
        
        // Wait a moment for responses to arrive
        .wait(1000);
    .

+no_certified_reputation[source(Agent)]
    :  true
    <-  .print("Agent ", Agent, " has no certified reputation ratings");
    .

+no_witness_reputation[source(Agent)]
    :  true
    <-  .print("Agent ", Agent, " has no witness reputation ratings");
    .

/* 
 * Plan for reacting to the addition of the goal !select_reading(TempReadings, Celsius)
 * Triggering event: addition of goal !select_reading(TempReadings, Celsius)
 * Context: true (the plan is always applicable)
 * Body: selects the temperature reading from the agent with the highest combined rating 
 *       using interaction trust, certified reputation, and witness reputation
 */
@select_reading_task_4_plan
+!select_reading(TempReadings, Celsius)
    :  true
    <-  // Collect all agent-temperature pairs
        .findall([Agent, Temp], temperature(Temp)[source(Agent)], AgentTemps);
        
        // Create a list to store agent-temperature-combined trust triplets
        .findall(
            [CombinedRating, Agent, Temp],
            (
                .member([Agent, Temp], AgentTemps) &
                
                // Calculate IT_AVG (Interaction Trust Average)
                .findall(Rating, interaction_trust(acting_agent, Agent, _, Rating), ITRatings) &
                (
                    (.length(ITRatings, ITLen) & ITLen > 0 &
                     Sum_IT = math.sum(ITRatings) &
                     IT_AVG = Sum_IT / ITLen)
                    |
                    (.length(ITRatings, 0) & IT_AVG = 0)
                ) &
                
                // Calculate CR (Certified Reputation)
                .findall(CRating, certified_reputation(_, Agent, _, CRating), CRRatings) &
                (
                    (.length(CRRatings, CRLen) & CRLen > 0 &
                     Sum_CR = math.sum(CRRatings) &
                     CR = Sum_CR / CRLen)
                    |
                    (.length(CRRatings, 0) & CR = 0)
                ) &
                
                // Calculate WR_AVG (Witness Reputation Average)
                .findall(WRating, witness_reputation(_, Agent, _, WRating), WRRatings) &
                (
                    (.length(WRRatings, WRLen) & WRLen > 0 &
                     Sum_WR = math.sum(WRRatings) &
                     WR_AVG = Sum_WR / WRLen)
                    |
                    (.length(WRRatings, 0) & WR_AVG = 0)
                ) &
                
                // Calculate IT_CR_WR (Combined Rating) using the weighted formula
                CombinedRating = (1/3) * IT_AVG + (1/3) * CR + (1/3) * WR_AVG &
                
                .print("Agent ", Agent, " has IT_AVG: ", IT_AVG, ", CR: ", CR, ", WR_AVG: ", WR_AVG, ", Combined: ", CombinedRating)
            ),
            CombinedRatingsList
        );
        
        // Check if we have any agents with combined ratings
        if (.length(CombinedRatingsList, ListLen) & ListLen > 0) {
            // Sort the list by combined rating (descending)
            .sort(CombinedRatingsList, SortedList);
            .reverse(SortedList, ReversedList);
            
            // Get the first element (highest combined rating)
            .nth(0, ReversedList, [BestRating, BestAgent, BestTemp]);
            
            .print("Agent with highest combined rating is ", BestAgent, " with rating ", BestRating);
            Celsius = BestTemp;
        } else {
            // Fallback if no ratings available
            .print("No combined ratings found, selecting first temperature");
            .nth(0, TempReadings, Celsius);
        }
    .

/* 
 * Plan for reacting to the addition of the goal !manifest_temperature
 * Triggering event: addition of goal !manifest_temperature
 * Context: the agent believes that a WoT TD of an onto:PhantomX is located at Location
 * Body: collects temperatures, selects the one from agent with highest combined rating, and manifests it
 */
@manifest_temperature_plan 
+!manifest_temperature
    :  robot_td(Location)
    <-  // Collect all temperature readings
        .findall(Temp, temperature(Temp)[source(_)], TempReadings);
        .print("Collected temperature readings: ", TempReadings);
        
        if (.length(TempReadings, Len) & Len > 0) {
            // Request certified reputation ratings from temperature readers
            !request_certified_reputation;
            
            // Request witness reputation ratings from temperature readers
            !request_witness_reputation;
            
            // Use the select_reading plan to pick the temperature from the agent with highest combined rating
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