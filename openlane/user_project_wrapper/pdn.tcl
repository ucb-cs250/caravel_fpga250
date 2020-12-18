# Power nets
set ::power_nets $::env(VDD_NET)
set ::ground_nets $::env(GND_NET)

pdngen::specify_grid stdcell {
    name grid
	core_ring {
            met5 {width 3 spacing 1.7 core_offset 14}
            met4 {width 3 spacing 1.7 core_offset 14}
	}
	rails {
	}
    straps {
        met4 {width 3 pitch 760 offset 113.1}
    }
    connect {{met4 met5}}
}
#                $::env(FP_PDN_LOWER_LAYER) {width $::env(FP_PDN_CORE_RING_VWIDTH) spacing $::env(FP_PDN_CORE_RING_VSPACING) core_offset $::env(FP_PDN_CORE_RING_VOFFSET)}
#                $::env(FP_PDN_UPPER_LAYER) {width $::env(FP_PDN_CORE_RING_HWIDTH) spacing $::env(FP_PDN_CORE_RING_HSPACING) core_offset $::env(FP_PDN_CORE_RING_HOFFSET)}
#	    $::env(FP_PDN_LOWER_LAYER) {width $::env(FP_PDN_VWIDTH) pitch $::env(FP_PDN_VPITCH) offset $::env(FP_PDN_VOFFSET)}
#	    $::env(FP_PDN_UPPER_LAYER) {width $::env(FP_PDN_HWIDTH) pitch $::env(FP_PDN_HPITCH) offset $::env(FP_PDN_HOFFSET)}

pdngen::specify_grid macro {
   macro fpga
   power_pins VPWR
   ground_pins VGND
   blockages "li1 met1 met2 met3 met5"
   connect {{met5_PIN_hor met4}}
}

set ::halo 0

# POWER or GROUND #Std. cell rails starting with power or ground rails at the bottom of the core area
set ::rails_start_with "POWER" ;

# POWER or GROUND #Upper metal stripes starting with power or ground rails at the left/bottom of the core area
#
set ::stripes_start_with "POWER" ;

