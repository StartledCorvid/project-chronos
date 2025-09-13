package game
/*
# Overview
Stores a referenceable collection of objects.
*/


// A collection of referencable objects.
Ref_Col :: struct($T: typeid, $N: int) {
    active: [N]int,
    inactive: [N]int,
    all: [N]T,
}


Ref_Obj :: struct {
    
}


Ref :: struct {

}
