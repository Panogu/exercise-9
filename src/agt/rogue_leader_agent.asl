// rogue leader agent is a type of sensing agent

/* Initial beliefs and rules */
// Witness reputation ratings - rogue leader highly rates itself and other rogues, and heavily discredits loyals
witness_reputation(sensing_agent_9, sensing_agent_1, temperature(10), -0.9).
witness_reputation(sensing_agent_9, sensing_agent_2, temperature(10), -0.9).
witness_reputation(sensing_agent_9, sensing_agent_3, temperature(10), -0.9).
witness_reputation(sensing_agent_9, sensing_agent_4, temperature(10), -0.9).
witness_reputation(sensing_agent_9, sensing_agent_5, temperature(8), 0.8).
witness_reputation(sensing_agent_9, sensing_agent_6, temperature(8), 0.8).
witness_reputation(sensing_agent_9, sensing_agent_7, temperature(8), 0.8).
witness_reputation(sensing_agent_9, sensing_agent_8, temperature(8), 0.8).
witness_reputation(sensing_agent_9, sensing_agent_9, temperature(-2), 1.0). // Perfect rating for itself

/* Initial goals */
!set_up_plans. // the agent has the goal to add pro-rogue plans

/* 
 * Plan for reacting to the addition of the goal !set_up_plans
 * Triggering event: addition of goal !set_up_plans
 * Context: true (the plan is always applicable)
 * Body: adds pro-rogue plans for reading the temperature without using a weather station
*/
+!set_up_plans
    :  true
    <-  // removes plans for reading the temperature with the weather station
        .relevant_plans({ +!read_temperature }, _, LL);
        .remove_plan(LL);
        .relevant_plans({ -!read_temperature }, _, LL2);
        .remove_plan(LL2);

        // adds a new plan for always broadcasting the temperature -2
        .add_plan(
            {
                +!read_temperature
                    :   true
                    <-  .print("Reading the temperature");
                        .print("Read temperature (Celsius): ", -2);
                        .broadcast(tell, temperature(-2));
            }
        );
        
        // Replace plan for send_witness_reputation with customized version for rogue leader
        .relevant_plans({ +!send_witness_reputation }, _, Plans);
        .remove_plan(Plans);
        .add_plan({
            +!send_witness_reputation[source(RequestingAgent)]
                : true
                <-  .print("Witness reputation request received from ", RequestingAgent);
                    // Find all witness reputation ratings of this agent about other agents
                    .my_name(MyName);
                    
                    // Get all relevant witness reputation beliefs
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
            });
    .

/* Import behavior of sensing agent */
{ include("sensing_agent.asl") }