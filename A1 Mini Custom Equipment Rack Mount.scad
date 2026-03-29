//Number of rack units for the front pannel
Rack_Height = 1.5; // [0.5:0.5:2]

//When set to true, show partial holes at edges
Half_Height_Holes = true; // [true:Show partial holes at edges, false:Hide partial holes]

//Width of the equipment to house 
Equipment_Width = 115.2; //[75.0:0.1:160.0]
//Depth of the equipment to house 
Equipment_Depth = 108.0; //[25.0:0.1:172.0]
//Height of the equipment to house 
Equipment_Height = 51.3; // [24.0:0.1:70.0]

//Front to back holes for cables.
Front_Cable_Holes = false; // [true:Show front wire holes, false:Hide front wire holes]

//Diameter of cable holes
Cable_Diameter = 5; //[3.0:0.1:6.0] 

//Honeycomb air holes
Air_Holes = true; // [true:Show air holes, false:Hide air holes]

//Exploded view print orientated, set to false for an assembed view. 
Print_Orientation = true; // [true: Place on printbed, false: Facing forward]

//Thickness of case walls
Case_Thickness = 5; //[3.0:0.1:5.0] 
Tolerance = 0.42;

/* [Hidden] */
height = 44.25 * Rack_Height;
rack_width = 254.0; // [ 254.0:10 inch, 152.4:6 inch]

a1_mini = (Equipment_Width > 160 || Equipment_Width < 40 || Equipment_Height < 24 || Equipment_Depth < 25) ? false : true; // [true: cuts for A1 Mini, max switch width 160mm, false: no cuts]
a1_mini_exploded = (a1_mini && Print_Orientation) ? true : false; // [true: show split parts exploded, false: show assembled]

// Helper functions below the hidden section only
function center_offset(outer, inner) = (outer - inner) / 2;

function a1_curve_z(u, width, depth, cutoff) =
    min(
        depth * (1 - sqrt(max(0, 1 - pow(u / width, 2)))),
        depth * cutoff
    );

// The main module containing all internal variables
module switch_mount(Equipment_Width, Equipment_Height, Equipment_Depth) {
    // Rack-standard values
    usable_rack_width = (rack_width == 152.4) ? 120.65 : 221.5;
    rack_hole_spacing_x = (rack_width == 152.4) ? 136.526 : 236.525;
    rack_slot_len = (rack_width == 152.4) ? 6.5 : 10.0;
    rack_slot_height = (rack_width == 152.4) ? 3.25 : 7.0;

    chassis_width = min(Equipment_Width + (2 * Case_Thickness), usable_rack_width);
    front_thickness = 3.0;
    corner_radius = 4.0;
    chassis_edge_radius = 2.0;

    zip_tie_hole_count = 8;
    zip_tie_hole_width = 1.5;
    zip_tie_hole_length = 5;
    zip_tie_indent_depth = 2;
    zip_tie_cutout_depth = 7;

    chassis_depth_main = Equipment_Depth + zip_tie_cutout_depth;
    chassis_depth_indented = chassis_depth_main - zip_tie_indent_depth;

    hole_total_width = zip_tie_hole_count * zip_tie_hole_width;
    space_between_holes = (rack_width - hole_total_width) / (zip_tie_hole_count + 1);

    $fn = 64;

    // Calculated dimensions
    cutout_w = Equipment_Width + (2 * Tolerance);
    cutout_h = Equipment_Height + (2 * Tolerance);
    cutout_x = center_offset(rack_width, cutout_w);
    cutout_y = center_offset(height, cutout_h);

    // Common body placement values
    side_margin = center_offset(rack_width, chassis_width);
    chassis_height = Equipment_Height + (2 * Case_Thickness);

    // A1 Mini split geometry
    a1_dovetail_clearance = 0.10;
    a1_eps = 0.02;
    a1_curve_steps = 64;
    a1_curve_depth_cutoff = 0.5;
    a1_curve_target_width = min(185 - Equipment_Width, 60);
    a1_curve_target_depth = min(Equipment_Depth / a1_curve_depth_cutoff, 60);

    // Captured dovetail:
    // narrow opening face is flush with the chassis body
    // wider root face is inside the side parts / tongues
    a1_dovetail_depth = 4;
    a1_dovetail_root_h = max(8, Equipment_Height - 8);
    a1_dovetail_open_h = max(4, a1_dovetail_root_h - 8);

    // Hidden overlap so the male tongues merge into the centre body as one solid
    a1_join_overlap = 0.20;

    a1_curve_width = max(a1_eps, min(a1_curve_target_width, side_margin));
    a1_curve_depth = max(a1_eps, min(a1_curve_target_depth, chassis_depth_main / a1_curve_depth_cutoff));
    a1_curve_height = max(a1_eps, chassis_height - 2 * chassis_edge_radius);
    a1_curve_y = center_offset(height, chassis_height) + chassis_edge_radius;

    // Split planes are flush with the chassis body side faces
    left_split_x = side_margin;
    right_split_x = side_margin + chassis_width;

    a1_root_h = min(a1_dovetail_root_h, a1_curve_height);
    a1_open_h = min(a1_dovetail_open_h, a1_root_h);
    a1_depth = min(a1_dovetail_depth, a1_curve_width);

    // Left interface: opening flush with chassis body, root inside left side part
    left_root_x = left_split_x - a1_depth;
    left_open_x = left_split_x;

    // Right interface: opening flush with chassis body, root inside right side part
    right_open_x = right_split_x;
    right_root_x = right_split_x + a1_depth;

    root_y0 = a1_curve_y + center_offset(a1_curve_height, a1_root_h);
    root_y1 = root_y0 + a1_root_h;
    open_y0 = a1_curve_y + center_offset(a1_curve_height, a1_open_h);
    open_y1 = open_y0 + a1_open_h;

    // Lift side parts above the centre part in exploded view
    a1_explode_lift = height + 2.9;
    explode_side_x = Equipment_Width / 2;
    explode_side_y = a1_explode_lift / 2;
    explode_center_y = -a1_explode_lift / 2;

    // Helper modules
    module capsule_slot_2d(L, H) {
        hull() {
            translate([-L/2 + H/2, 0]) circle(r = H/2);
            translate([ L/2 - H/2, 0]) circle(r = H/2);
        }
    }

    module rounded_rect_2d(w, h, r) {
        hull() {
            translate([r,   r])   circle(r = r);
            translate([w-r, r])   circle(r = r);
            translate([w-r, h-r]) circle(r = r);
            translate([r,   h-r]) circle(r = r);
        }
    }

    module rounded_chassis_profile(width, height, radius, depth) {
        hull() {
            translate([radius,         radius,          0]) cylinder(h = depth, r = radius);
            translate([width - radius, radius,          0]) cylinder(h = depth, r = radius);
            translate([radius,         height - radius, 0]) cylinder(h = depth, r = radius);
            translate([width - radius, height - radius, 0]) cylinder(h = depth, r = radius);
        }
    }

    // A1 Mini curved side profile in local X-Z, extruded in Y
    module a1_curve_profile_2d() {
        polygon(
            points = concat(
                [[0, 0]],
                [
                    for (i = [0:a1_curve_steps])
                        let (
                            u = a1_curve_width * i / a1_curve_steps,
                            z = a1_curve_z(u, a1_curve_width, a1_curve_depth, a1_curve_depth_cutoff)
                        )
                        [u, z]
                ],
                [[a1_curve_width, 0]]
            )
        );
    }

    module a1_curve_raw() {
        translate([0, a1_curve_height, 0])
            rotate([90, 0, 0])
                linear_extrude(height = a1_curve_height, center = false, convexity = 10)
                    a1_curve_profile_2d();
    }

    module a1_left_curve_raw() {
        translate([left_split_x - a1_curve_width, a1_curve_y, 0])
            a1_curve_raw();
    }

    module a1_right_curve_raw() {
        translate([right_split_x + a1_curve_width, a1_curve_y, 0])
            mirror([1, 0, 0])
                a1_curve_raw();
    }

    // Dovetail profiles in XY
    module left_dovetail_profile_xy() {
        polygon(points = [
            [left_root_x, root_y0],
            [left_root_x, root_y1],
            [left_open_x, open_y1],
            [left_open_x, open_y0]
        ]);
    }

    module right_dovetail_profile_xy() {
        polygon(points = [
            [right_open_x, open_y0],
            [right_open_x, open_y1],
            [right_root_x, root_y1],
            [right_root_x, root_y0]
        ]);
    }

    // Male profiles extend slightly into the centre body so the union is a true solid merge
    module left_male_dovetail_profile_xy() {
        polygon(points = [
            [left_root_x, root_y0],
            [left_root_x, root_y1],
            [left_open_x + a1_join_overlap, open_y1],
            [left_open_x + a1_join_overlap, open_y0]
        ]);
    }

    module right_male_dovetail_profile_xy() {
        polygon(points = [
            [right_open_x - a1_join_overlap, open_y0],
            [right_open_x - a1_join_overlap, open_y1],
            [right_root_x, root_y1],
            [right_root_x, root_y0]
        ]);
    }

    // Create the main body as a separate module
    module main_body() {
        union() {
            // Front panel
            linear_extrude(height = front_thickness)
                rounded_rect_2d(rack_width, height, corner_radius);

            // Chassis body
            translate([side_margin, center_offset(height, chassis_height), front_thickness])
                rounded_chassis_profile(chassis_width, chassis_height, chassis_edge_radius, chassis_depth_main - front_thickness);

            // A1 Mini side curve bodies
            if (a1_mini) {
                a1_left_curve_raw();
                a1_right_curve_raw();
            }
        }
    }

    // Apply all functional cutouts to the complete body
    module functional_body() {
        difference() {
            main_body();
            union() {
                switch_cutout();
                all_rack_holes();
                zip_tie_features();
                if (Front_Cable_Holes) {
                    power_wire_cutouts();
                }
                if (Air_Holes) {
                    air_hole_pattern();
                }
            }
        }
    }

    // Create switch cutout with proper lip
    module switch_cutout() {
        lip_thickness = 1.2;
        lip_depth = 0.60;

        // Main cutout minus lip (centered)
        translate([
            center_offset(rack_width, cutout_w - 2 * lip_thickness),
            center_offset(height, cutout_h - 2 * lip_thickness),
            -Tolerance
        ])
            cube([cutout_w - 2 * lip_thickness, cutout_h - 2 * lip_thickness, chassis_depth_main]);

        // Switch cutout above the lip (centered)
        translate([
            center_offset(rack_width, cutout_w),
            center_offset(height, cutout_h),
            lip_depth
        ])
            cube([cutout_w, cutout_h, chassis_depth_main]);
    }

    // Create all rack holes
    module all_rack_holes() {
        // Rack standard: 3 holes per U, with specific positioning
        // Each U is 44.45mm, holes are at specific positions within each U
        hole_left_x = center_offset(rack_width, rack_hole_spacing_x);
        hole_right_x = (rack_width + rack_hole_spacing_x) / 2;

        // Standard rack hole positions within each 1U (44.45mm) unit:
        // First hole: 6.35mm from top of U
        // Second hole: 22.225mm from top of U (middle)
        // Third hole: 38.1mm from top of U (6.35mm from bottom)
        u_hole_positions = [6.35, 22.225, 38.1];

        // Calculate how many full and partial U units we need to consider
        max_u = ceil(Rack_Height);

        for (side_x = [hole_left_x, hole_right_x]) {
            for (u = [0:max_u-1]) {
                for (hole_pos = u_hole_positions) {
                    hole_y = height - (u * 44.45 + hole_pos);

                    fully_inside = (hole_y >= rack_slot_height / 2 && hole_y <= height - rack_slot_height / 2);
                    partially_inside = (hole_y + rack_slot_height / 2 > 0 && hole_y - rack_slot_height / 2 < height);
                    show_hole = fully_inside || (Half_Height_Holes && partially_inside && !fully_inside);

                    if (show_hole) {
                        translate([side_x, hole_y, 0])
                            linear_extrude(height = chassis_depth_main)
                                capsule_slot_2d(rack_slot_len, rack_slot_height);
                    }
                }
            }
        }
    }

    // Power wire cutouts: configurable diameter holes at top and bottom rack hole positions
    module power_wire_cutouts() {
        hole_spacing_x = Equipment_Width;
        hole_left_x = center_offset(rack_width, hole_spacing_x) - (Cable_Diameter / 5);
        hole_right_x = (rack_width + hole_spacing_x) / 2 + (Cable_Diameter / 5);

        // Midplane of switch opening
        mid_y = center_offset(height, Equipment_Height) + Equipment_Height / 2;

        for (side_x = [hole_left_x, hole_right_x]) {
            translate([side_x, mid_y, 0])
                linear_extrude(height = chassis_depth_main)
                    circle(d = Cable_Diameter);
        }
    }

    // Create zip tie holes and indents
    module zip_tie_features() {
        // Zip tie holes
        for (i = [0:zip_tie_hole_count-1]) {
            x_pos = center_offset(rack_width, Equipment_Width) + (Equipment_Width / (zip_tie_hole_count + 1)) * (i + 1);
            translate([x_pos, 0, Equipment_Depth])
                cube([zip_tie_hole_width, height, zip_tie_hole_length]);
        }

        // Zip tie indents (top and bottom)
        x_pos = center_offset(rack_width, Equipment_Width);
        local_chassis_height = Equipment_Height + (2 * Case_Thickness);

        // Bottom indent
        translate([x_pos, center_offset(height, local_chassis_height), Equipment_Depth])
            cube([Equipment_Width, zip_tie_indent_depth, zip_tie_cutout_depth]);

        // Top indent
        translate([x_pos, center_offset(height, local_chassis_height) + local_chassis_height - zip_tie_indent_depth, Equipment_Depth])
            cube([Equipment_Width, zip_tie_indent_depth, zip_tie_cutout_depth]);
    }

    // Simplified air holes with staggered honeycomb pattern on all faces
    module air_hole_pattern() {
        hole_d = 16;
        spacing_x = 15;  // Horizontal spacing (X and Y directions)
        spacing_z = 17;  // Vertical spacing (Z direction) - tighter to match visual density
        margin = 3;      // Keep holes away from edges

        // BACK FACE HOLES (Y-axis through back)
        available_width = Equipment_Width - (2 * margin);
        available_depth = Equipment_Depth - (2 * margin);

        x_cols = floor(available_width / spacing_x);
        z_rows = floor(available_depth / spacing_z);

        actual_grid_width = (x_cols - 1) * spacing_x;
        actual_grid_depth = (z_rows - 1) * spacing_z;

        cutout_center_x = rack_width / 2;
        cutout_center_z = front_thickness + Equipment_Depth / 2;

        x_start = cutout_center_x - actual_grid_width / 2;
        z_start = cutout_center_z - actual_grid_depth / 2;

        if (x_cols > 0 && z_rows > 0) {
            for (i = [0:x_cols-1]) {
                for (j = [0:z_rows-1]) {
                    z_offset = (i % 2 == 1) ? spacing_z / 2 : 0;
                    x_pos = x_start + i * spacing_x;
                    z_pos = z_start + j * spacing_z + z_offset;

                    if (z_pos + hole_d / 2 <= cutout_center_z + Equipment_Depth / 2 - margin &&
                        z_pos - hole_d / 2 >= cutout_center_z - Equipment_Depth / 2 + margin) {
                        translate([x_pos, height, z_pos])
                            rotate([90, 0, 0])
                                cylinder(h = height, d = hole_d, $fn = 6);
                    }
                }
            }
        }

        // SIDE FACE HOLES (X-axis through left and right sides)
        available_height = Equipment_Height - (2 * margin);
        available_side_depth = a1_mini
            ? Equipment_Depth - (2 * margin) - (a1_curve_target_depth * a1_curve_depth_cutoff)
            : Equipment_Depth - (2 * margin);

        y_cols = floor(available_height / spacing_x);
        z_rows_side = floor(available_side_depth / spacing_z);

        actual_grid_height = (y_cols - 1) * spacing_x;
        actual_grid_depth_side = (z_rows_side - 1) * spacing_z;

        cutout_center_y = height / 2;
        y_start = cutout_center_y - actual_grid_height / 2;
        z_start_side = cutout_center_z - actual_grid_depth_side / 2 + (a1_curve_target_depth * a1_curve_depth_cutoff) / 2;

        if (y_cols > 0 && z_rows_side > 0) {
            for (side = [0, 1]) {
                side_x = side == 0 ? side_margin : rack_width - side_margin;

                for (i = [0:y_cols-1]) {
                    for (j = [0:z_rows_side-1]) {
                        z_offset = (i % 2 == 1) ? spacing_z / 2 : 0;
                        y_pos = y_start + i * spacing_x;
                        z_pos = z_start_side + j * spacing_z + z_offset;

                        if (z_pos + hole_d / 2 <= cutout_center_z + Equipment_Depth / 2 - margin &&
                            z_pos - hole_d / 2 >= cutout_center_z - Equipment_Depth / 2 + margin) {
                            translate([side_x, y_pos, z_pos]) {
                                rotate([0, 90, 0]) {
                                    rotate([0, 0, 90])
                                        cylinder(h = chassis_width, d = hole_d, $fn = 6);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Split masks: these also split the front panel wings correctly
    module left_region() {
        translate([-a1_eps, -a1_eps, -a1_eps])
            cube([left_split_x + a1_eps, height + 2 * a1_eps, chassis_depth_main + 2 * a1_eps]);
    }

    module center_region() {
        translate([left_split_x, -a1_eps, -a1_eps])
            cube([chassis_width, height + 2 * a1_eps, chassis_depth_main + 2 * a1_eps]);
    }

    module right_region() {
        translate([right_split_x, -a1_eps, -a1_eps])
            cube([rack_width - right_split_x + a1_eps, height + 2 * a1_eps, chassis_depth_main + 2 * a1_eps]);
    }

    // Female grooves cut into the side parts.
    // These are true captured dovetails:
    // opening is flush with the chassis body, root is deeper inside the side parts.
    module left_female_groove() {
        translate([0, 0, -a1_eps])
            linear_extrude(height = chassis_depth_main + 2 * a1_eps, center = false, convexity = 10)
                offset(delta = a1_dovetail_clearance)
                    left_dovetail_profile_xy();
    }

    module right_female_groove() {
        translate([0, 0, -a1_eps])
            linear_extrude(height = chassis_depth_main + 2 * a1_eps, center = false, convexity = 10)
                offset(delta = a1_dovetail_clearance)
                    right_dovetail_profile_xy();
    }

    // Male tongues added to the centre part with slight overlap into the body
    module left_male_tongue() {
        intersection() {
            functional_body();
            translate([0, 0, -a1_eps])
                linear_extrude(height = chassis_depth_main + 2 * a1_eps, center = false, convexity = 10)
                    offset(delta = -a1_dovetail_clearance)
                        left_male_dovetail_profile_xy();
        }
    }

    module right_male_tongue() {
        intersection() {
            functional_body();
            translate([0, 0, -a1_eps])
                linear_extrude(height = chassis_depth_main + 2 * a1_eps, center = false, convexity = 10)
                    offset(delta = -a1_dovetail_clearance)
                        right_male_dovetail_profile_xy();
        }
    }

    // Final split parts
    module a1_left_part() {
        difference() {
            intersection() {
                functional_body();
                left_region();
            }
            left_female_groove();
        }
    }

    module a1_center_part() {
        union() {
            intersection() {
                functional_body();
                center_region();
            }
            left_male_tongue();
            right_male_tongue();
        }
    }

    module a1_right_part() {
        difference() {
            intersection() {
                functional_body();
                right_region();
            }
            right_female_groove();
        }
    }

    module a1_assembled_parts() {
        color([0.20, 0.55, 0.95, 0.90]) a1_left_part();
        color([0.20, 0.55, 0.95, 0.90]) a1_center_part();
        color([0.20, 0.55, 0.95, 0.90]) a1_right_part();
    }

    // Left and right parts lifted above the centre part
    module a1_exploded_parts() {
        translate([ explode_side_x, explode_side_y, 0])
            color([0.20, 0.55, 0.95, 0.90]) a1_left_part();

        translate([0, explode_center_y, 0])
            color([0.20, 0.55, 0.95, 0.90]) a1_center_part();

        translate([-explode_side_x, explode_side_y, 0])
            color([0.20, 0.55, 0.95, 0.90]) a1_right_part();
    }

    // Final output
    translate([-rack_width/2, -height/2, 0]) {
        if (a1_mini) {
            if (a1_mini_exploded) {
                a1_exploded_parts();
            } else {
                a1_assembled_parts();
            }
        } else {
            functional_body();
        }
    }
}

// Call the module
if (Print_Orientation) {
    switch_mount(Equipment_Width, Equipment_Height, Equipment_Depth);
} else {
    rotate([-90, 0, 0])
        translate([0, -height/2, -Equipment_Depth/2])
            switch_mount(Equipment_Width, Equipment_Height, Equipment_Depth);
}
