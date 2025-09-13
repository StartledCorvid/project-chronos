package game


/*
# Overview
A general state machine. Primarily used for animation, but could also be
used for things like AI.
*/


State_Machine :: struct {
    current_state: int,
    states: [dynamic]State_Machine_State,
}


State_Machine_State :: struct {
    
}


State_Machine_Transition :: union {
    State_Machine_Trigger,
    State_Machine_Condition,
}


State_Machine_Trigger :: struct {
    
}


State_Machine_Condition :: struct {

}

