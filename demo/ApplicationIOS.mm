//
//  SoftwareRenderer
//

#include <iostream>
#include <stdexcept>
#include "ApplicationIOS.hpp"

demo::ApplicationIOS* sharedApplication;

@interface AppDelegate: UIResponder<UIApplicationDelegate>

@end

@implementation AppDelegate

-(BOOL)application:(__unused UIApplication*)application willFinishLaunchingWithOptions:(__unused NSDictionary*)launchOptions
{
    sharedApplication->createWindow();

    return YES;
}

-(BOOL)application:(__unused UIApplication*)application didFinishLaunchingWithOptions:(__unused NSDictionary*)launchOptions
{
    return YES;
}

-(void)applicationDidBecomeActive:(__unused UIApplication*)application
{
}

-(void)applicationWillResignActive:(__unused UIApplication*)application
{
}

-(void)applicationDidEnterBackground:(__unused UIApplication*)application
{
}

-(void)applicationWillEnterForeground:(__unused UIApplication*)application
{
}

-(void)applicationWillTerminate:(__unused UIApplication*)application
{
}

-(void)applicationDidReceiveMemoryWarning:(__unused UIApplication*)application
{
}

@end

@interface ViewController: UIViewController
{
    demo::ApplicationIOS* application;
}

@end

@implementation ViewController

-(id)initWithWindow:(demo::ApplicationIOS*)initApplication
{
    if (self = [super init])
        application = initApplication;

    return self;
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

-(void)textFieldDidChange:(__unused id)sender
{
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    application->didResize(size.width, size.height);
}

-(void)deviceOrientationDidChange:(NSNotification*)note
{
    if (self.view)
    {
        const CGSize size = self.view.frame.size;

        application->didResize(size.width, size.height);
    }
}

@end

@interface Canvas: UIView
{
    demo::ApplicationIOS* application;
}

@end

@implementation Canvas

-(id)initWithFrame:(CGRect)frameRect andApplication:(demo::ApplicationIOS*)initApplication
{
    if (self = [super initWithFrame:frameRect])
    {
        application = initApplication;
    }

    return self;
}

-(void)drawRect:(CGRect)dirtyRect
{
    [super drawRect:dirtyRect];

    application->draw();
}

-(void)draw:(__unused NSTimer*)timer
{
    [self setNeedsDisplay];
}

@end

static const void* getBytePointer(void* info)
{
    sr::RenderTarget* renderTarget = static_cast<sr::RenderTarget*>(info);

    return renderTarget->getFrameBuffer().getData().data();
}

namespace demo
{
    ApplicationIOS::ApplicationIOS()
    {
        sharedApplication = this;
        pool = [[NSAutoreleasePool alloc] init];
    }

    ApplicationIOS::~ApplicationIOS()
    {
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorSpace);

        if (timer) [timer release];
        if (content) [content release];
        if (window)
        {
            window.rootViewController = nil;
            [window release];
        }
        if (pool) [pool release];
    }

    void ApplicationIOS::createWindow()
    {
        screen = [UIScreen mainScreen];

        window = [[UIWindow alloc] initWithFrame:[screen bounds]];

        viewController = [[[ViewController alloc] initWithWindow:this] autorelease];
        window.rootViewController = viewController;

        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:viewController selector:@selector(deviceOrientationDidChange:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:[UIDevice currentDevice]];

        const CGRect windowFrame = [window bounds];

        width = static_cast<std::size_t>(windowFrame.size.width * screen.scale);
        height = static_cast<std::size_t>(windowFrame.size.height * screen.scale);

        content = [[Canvas alloc] initWithFrame:windowFrame andApplication:this];
        content.contentScaleFactor = screen.scale;
        viewController.view = content;

        componentsPerPixel = 4;
        bitsPerComponent = sizeof(std::uint8_t) * 8;

        CGDataProviderDirectCallbacks providerCallbacks = {
            0,
            getBytePointer,
            nullptr,
            nullptr,
            nullptr
        };

        colorSpace = CGColorSpaceCreateDeviceRGB();
        provider = CGDataProviderCreateDirect(&renderTarget, width * height * componentsPerPixel, &providerCallbacks);

        [window makeKeyAndVisible];

        timer = [[NSTimer scheduledTimerWithTimeInterval:0.016 target:content selector:@selector(draw:) userInfo:[NSValue valueWithPointer:this] repeats:YES] retain];

        setup();
    }

    void ApplicationIOS::draw()
    {
        render();

        CGImageRef image = CGImageCreate(width, height, bitsPerComponent,
                                         bitsPerComponent * componentsPerPixel,
                                         componentsPerPixel * width,
                                         colorSpace,
                                         kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipLast,
                                         provider, nullptr, FALSE, kCGRenderingIntentDefault);

        CGContextRef context = UIGraphicsGetCurrentContext();

        CGContextDrawImage(context, [content frame], image);
        CGContextFlush(context);

        CGImageRelease(image);
    }

    void ApplicationIOS::didResize(CGFloat newWidth, CGFloat newHeight)
    {
        width = static_cast<std::size_t>(newWidth * screen.scale);
        height = static_cast<std::size_t>(newHeight * screen.scale);

        CGDataProviderRelease(provider);

        CGDataProviderDirectCallbacks providerCallbacks = {
            0,
            getBytePointer,
            nullptr,
            nullptr,
            nullptr
        };

        provider = CGDataProviderCreateDirect(&renderTarget, width * height * componentsPerPixel, &providerCallbacks);
        
        onResize();
    }

    void ApplicationIOS::run(int argc, char* argv[])
    {
        UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }

    std::string Application::getResourcePath()
    {
        CFBundleRef bundle = CFBundleGetMainBundle(); // [NSBundle mainBundle]
        CFURLRef path = CFBundleCopyResourcesDirectoryURL(bundle); // [bundle resourceURL]

        if (path)
        {
            char resourceDirectory[CS_MAX_PATH];
            CFURLGetFileSystemRepresentation(path, TRUE, reinterpret_cast<UInt8*>(resourceDirectory), sizeof(resourceDirectory));
            CFRelease(path);
            return resourceDirectory;
        }
        else
            throw std::runtime_error("Failed to get current directory");

        return "";
    }
}

int main(int argc, char* argv[])
{
    try
    {
        demo::ApplicationIOS application;
        application.run(argc, argv);

        return EXIT_SUCCESS;
    }
    catch (const std::exception& e)
    {
        std::cerr << e.what() << std::endl;
        return EXIT_FAILURE;
    }
    catch (...)
    {
        return EXIT_FAILURE;
    }
}
