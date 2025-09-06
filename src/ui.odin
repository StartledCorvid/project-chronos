package game
/*
# Overview
An immediate-mode UI system using Raylib.
*/

// import rl "vendor:raylib"

MAX_NODES :: 1000


UI_Handle :: distinct Handle


UI_Graph :: struct {
    active_nodes: [MAX_NODES]int,
    inactive_nodes: [MAX_NODES]int,
    nodes: [MAX_NODES]UI_Node,
}


UI_Node_Type :: union {
    UI_Group,
}


UI_Node :: struct {
    type: UI_Node_Type,
}


UI_Alignment :: enum {
    Max,
    Min,
    Center,
}


UI_Direction :: enum {
    Vertical,
    Horizontal,
}


UI_Group :: struct {
    direction: UI_Direction,
    alignment: UI_Alignment,
}
