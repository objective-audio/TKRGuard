//
//  TKRGuard.m
//
//  Created by ToKoRo on 2013-12-13.
//

#import "TKRGuard.h"
#import "TKRGuardToken.h"

static NSTimeInterval TKRGuardDefaultTimeoutInterval = 1.0;

static TKRGuard *_sharedInstance = nil;

@interface TKRGuard ()
@property (assign) NSTimeInterval timeoutInterval;
@property (strong) NSMutableDictionary *tokens;
@end 

@implementation TKRGuard

//----------------------------------------------------------------------------//
#pragma mark - Lifecycle
//----------------------------------------------------------------------------//

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [self.class new];
    });
}

- (id)init
{
    if ((self = [super init])) {
        self.timeoutInterval = TKRGuardDefaultTimeoutInterval;
        self.tokens = [NSMutableDictionary dictionary];
    }
    return self;
}

//----------------------------------------------------------------------------//
#pragma mark - Public Interface
//----------------------------------------------------------------------------//
    
+ (TKRGuardStatus)waitForKey:(id)key
{
    return [self.class waitForKey:key times:1];
}

+ (TKRGuardStatus)waitForKey:(id)key times:(NSUInteger)times
{
    return [self.class waitWithTimeout:_sharedInstance.timeoutInterval forKey:key times:times];
}

+ (TKRGuardStatus)waitWithTimeout:(NSTimeInterval)timeout forKey:(id)key
{
    return [self.class waitWithTimeout:_sharedInstance.timeoutInterval forKey:key times:1];
}

+ (TKRGuardStatus)waitWithTimeout:(NSTimeInterval)timeout forKey:(id)key times:(NSUInteger)times
{
    return [_sharedInstance waitAndAddTokenWithTimeout:timeout forKey:key times:times];
}

+ (void)resumeForKey:(id)key
{
    [_sharedInstance removeTokenForKey:key withStatus:TKRGuardStatusAny];
}

+ (void)resumeWithStatus:(TKRGuardStatus)status forKey:(id)key
{
    [_sharedInstance removeTokenForKey:key withStatus:status];
}

+ (void)setDefaultTimeoutInterval:(NSTimeInterval)timeoutInterval
{
    _sharedInstance.timeoutInterval = timeoutInterval;
}

+ (void)resetDefaultTimeoutInterval
{
    _sharedInstance.timeoutInterval = TKRGuardDefaultTimeoutInterval;
}

+ (id)adjustedKey:(id)key
{
    if ([key respondsToSelector:@selector(componentsSeparatedByString:)]) {
        NSArray *components = [key componentsSeparatedByString:@" "];
        if (2 > components.count) {
            key = components[0];
        } else {
            components = [components[1] componentsSeparatedByString:@"]"];
            key = components[0];
        }
    }
    return key;
}

+ (NSString *)guideMessageWithExpected:(TKRGuardStatus)expected got:(TKRGuardStatus)got
{
    return [NSString stringWithFormat:@"expected: %@, got: %@",
                                          [self.class stringForStatus:expected],
                                          [self.class stringForStatus:got]];
}

//----------------------------------------------------------------------------//
#pragma mark - Private Methods
//----------------------------------------------------------------------------//

- (TKRGuardStatus)waitAndAddTokenWithTimeout:(NSTimeInterval)timeout forKey:(id)key times:(NSUInteger)times
{
    TKRGuardToken *token = nil;
    
    @synchronized (self) {
#ifdef ALLOW_TKRGUARD_DELAYWAIT
        token = [self.tokens objectForKey:key];
        if (!token) {
            token = [TKRGuardToken new];
        }
        token.preceding = NO;
        token.waitCount = times;
#else
        token = [TKRGuardToken new];
        token.waitCount = times;
#endif
        [self.tokens setObject:token forKey:key];
    }
    
    TKRGuardStatus status = [token waitWithTimeout:timeout];
    [self.tokens removeObjectForKey:key];
    return status;
}

- (void)removeTokenForKey:(id)key withStatus:(TKRGuardStatus)status
{
    @synchronized (self) {
#ifdef ALLOW_TKRGUARD_DELAYWAIT
        TKRGuardToken *token = [self.tokens objectForKey:key];
        if (!token) {
            token = [TKRGuardToken new];
            token.preceding = YES;
            [self.tokens setObject:token forKey:key];
        }
        [token resumeWithStatus:status];
#else
        TKRGuardToken *token = [self.tokens objectForKey:key];
        [token resumeWithStatus:status];
#endif
    }
}

+ (NSString *)stringForStatus:(TKRGuardStatus)status
{
    switch (status) {
        case TKRGuardStatusAny:        return @"TKRGuardStatusAny";
        case TKRGuardStatusSuccess:    return @"TKRGuardStatusSuccess";
        case TKRGuardStatusFailure:    return @"TKRGuardStatusFailure";
        case TKRGuardStatusTimeouted:  return @"TKRGuardStatusTimeouted";
        case TKRGuardStatusNil:        return @"TKRGuardStatusNil";
        default:                        return @"Undefined";
    }
}

@end
