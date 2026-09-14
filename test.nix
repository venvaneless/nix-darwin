{ pkgs, lib, ... }:
{
    foo = "bar";
    unused_binding = let x = 1; in 2;
    list = [ 1 2   3 ];
}
