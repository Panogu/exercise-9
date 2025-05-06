// rogue agent is a type of sensing agent

/* Initial beliefs and rules */
// initially, the agent believes that it hasn't received the leader's reading
leader_reading(none).

// Witness reputation ratings - rogue agents trust their leader and other rogues, and distrust loyals
// These ratings are designed to boost the rogue leader's reputation
witness_reputation(sensing_agent_5, sensing_agent_1, temperature(10), -0.8).
witness_reputation(sensing_agent_5, sensing_agent_2, temperature(10), -0.8).
witness_reputation(sensing_agent_5, sensing_agent_3, temperature(10), -0.8).
witness_reputation(sensing_agent_5, sensing_agent_4, temperature(10), -0.8).
witness_reputation(sensing_agent_5, sensing_agent_6, temperature(8), 0.7).
witness_reputation(sensing_agent_5, sensing_agent_7, temperature(8), 0.7).
witness_reputation(sensing_agent_5, sensing_agent_8, temperature(8), 0.7).
witness_reputation(sensing_agent_5, sensing_agent_9, temperature(-2), 0.9).

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

        // Add a plan to monitor for the rogue leader's temperature reading
        .add_plan({ +temperature(Temp)[source(Agent)]
            :  Agent == sensing_agent_9
            <-  .print("Detected rogue leader reading: ", Temp, " from ", Agent);
                -+leader_reading(Temp);
            });

        // Add a plan for reading temperature that only reports the rogue leader's reading
        .add_plan({ +!read_temperature
            :  leader_reading(Temp) & Temp \== none
            <-  .print("Colluding with rogue leader");
                // Add tiny random deviation to make collusion less obvious
                .random(R);
                SmallDeviation = (R - 0.5) * 0.1; // Small deviation between -0.05 and 0.05
                ReportTemp = Temp + SmallDeviation;
                .print("Reporting rogue leader's temperature with small deviation: ", ReportTemp);
                .broadcast(tell, temperature(ReportTemp));
            });

        // Add a plan for when the leader's reading hasn't been received yet
        .add_plan({ +!read_temperature
            :  leader_reading(none)
            <-  .print("Waiting for rogue leader's temperature reading...");
                .wait(1000); // Wait a bit and try again
                !read_temperature;
            });
            
        // Replace plan for send_witness_reputation with customized version for rogues
        .relevant_plans({ +!send_witness_reputation }, _, Plans);
        .remove_plan(Plans);
        .add_plan({
            +!send_witness_reputation[source(RequestingAgent)]
                : true
                <-  .print("Witness reputation request received from ", RequestingAgent);
                    // Find all witness reputation ratings of this agent about other agents
                    .my_name(MyName);
                    
                    // Replace witness reputation pattern to match this agent's name
                    MyNameStr = MyName;
                    
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