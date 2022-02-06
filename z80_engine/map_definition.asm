macro makeadr coordx,coordy
	vx={coordx}*30+12
	bytex=vx>>2 ; numéro d'octet
	vx=vx%4 ; ajustement à deux pixels à cause du x10
	vy={coordy}*30+5
	bloc=vy%8 ; numéro de bloc
	vy>>=3
	lapage=#C000 ; si on tombe bien, on commence au bon endroit mais on ajustera la fin
	defw lapage+vy*88+bloc*#800+bytex
mend

macro make_place laplace,cx,cy
defw {laplace}
makeadr {cx},{cy}
mend

macro make_place2 laplace1,laplace2,cx,cy
defw {laplace1}|2048
defw {laplace2}
makeadr {cx},{cy}
mend

macro make_place3 laplace1,laplace2,laplace3,cx,cy
defw {laplace1}|4096
defw {laplace2}
defw {laplace3}
makeadr {cx},{cy}
mend

map_tag

defs NBPLACES,0

map_definition

make_place2 398,239,0,1
make_place 195,0,2

defw 0 ; terminator

