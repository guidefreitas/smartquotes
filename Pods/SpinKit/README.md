SpinKit-ObjC
============

UIKit port of [SpinKit](https://github.com/tobiasahlin/SpinKit).

Usage
-----

Simply instantiate `RTSpinKitView` with the desired style and add to your view hierarchy.

    RTSpinKitView *spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleWave];
    [self.view addSubview:spinner];

Available styles:

* `RTSpinKitViewStylePlane`
* `RTSpinKitViewStyleBounce`
* `RTSpinKitViewStyleWave`
* `RTSpinKitViewStyleWanderingCubes`
* `RTSpinKitViewStylePulse`

MBProgressHUD
-------------

SpinKit integrates nicely with the amazing [MBProgressHUD](https://github.com/jdg/MBProgressHUD) library:

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.square = YES;
    hud.mode = MBProgressHUDModeCustomView;
    hud.customView = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleWave color:[UIColor whiteColor]];
    hud.labelText = NSLocalizedString(@"Loading", @"Loading");

Acknowledgements
----------------

Animations based on [SpinKit](https://github.com/tobiasahlin/SpinKit) by [Tobias Ahlin](https://github.com/tobiasahlin).
