// rogue agent is a type of sensing agent

/* Initial beliefs and rules */
// initially, the agent believes that it hasn't received the leader's reading
leader_reading(none).

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
    .

/* Import behavior of sensing agent */
{ include("sensing_agent.asl") }