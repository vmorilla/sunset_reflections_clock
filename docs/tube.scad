module vacuum_tube(
    main_height = 300, 
    main_radius = 80, 
    bell_radius = 40, 
    bell_angle = 70, 
    tip_height = 30, 
    tip_top_angle = -80
) {

    steps = $fn ? $fn : 10;

    bell_end = [cos(bell_angle) * main_radius, sin(bell_angle) * bell_radius];
    tip_bottom_angle = atan(tan(bell_angle) * bell_radius / main_radius);

    tip_end = [0, tip_height + sin(bell_angle) * bell_radius];

    main_points = [[0, -main_height], [main_radius, -main_height], [main_radius, 0]];

    shoulder_points = [ for(a = [0:bell_angle / steps:bell_angle]) arc_point(main_radius, bell_radius, a)];

    p1 = intersecting_point(tip_end, tip_top_angle, bell_end, tip_bottom_angle);

    tip_points = [ for(t = [0:1/steps:1]) bezier_point(bell_end, p1, tip_end, t) ];

    points = concat(main_points, shoulder_points, tip_points, [[0,0]] );

    translate([0,0, main_height]) rotate_extrude(convexity=2) {
        polygon(points);
    }
}

function bezier_point(p0, p1, p2, t) = pow(1 - t, 2) * p0 + 2 * t * (1 - t) * p1 + pow(t,2) * p2;

function intersecting_point(p0, a0, p1, a1) = 
    let(x = p0[0] + (p1[1] - p0[1]) / (tan(a0) - tan(a1))) 
    echo(a0, a1)
    [x, tan(a0) * (x - p0[0]) + p0[1]];

function arc_point(rx, ry, angle) = [rx * cos(angle), ry * sin(angle)];

module fillet(r, h) {
    translate([r / 2, r / 2, 0])

        difference() {
            cube([r + 0.01, r + 0.01, h], center = true);

            translate([r/2, r/2, 0])
                cylinder(r = r, h = h + 1, center = true);

        }
}

module tube() {
    //Grid
    color("red", 0.50) translate([0,150,0]) cube([100, 200, 100], true);

    //Tube
    color("grey", 0.25) rotate([-90, 0, 0]) vacuum_tube($fn = 100);

    //Stand
    color("blue") rotate([90, 0, 0]) cylinder(r = 90, h = 60, $fn = 100);
}

// Tubo coordenadas modelo
//tube();

// Tubos en el mundo
// translate([-310, 0, 0]) tube();
// translate([-110, 0, 0]) tube();
// translate([110, 0, 0]) tube();
// translate([310, 0, 0]) tube();

translate([0, -60, 0]) cube([900, 30, 250], center= true);

//color("yellow") fillet(10, 20);