//
//  TKRGuard.h
//
//  Created by ToKoRo on 2013-12-13.
//

#import "TKRGuardStatus.h"

#ifdef TKRGUARD_USE_KIWI

// For Kiwi
#ifndef fail
#define fail
#endif
#define TKRGUARD_FAILE fail

#else

// For XCTest
#define TKRGUARD_FAILE XCTFail

#endif

#define TKRGUARD_KEY ([TKRGuard adjustedKey:[NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__]])
#define TKRGUARD_TIMEOUT TKRGUARD_FAILE(@"TKRGuard timeouted")
#define TKRAssertEqualStatus__(v, e, l) TKRGuardStatus e__ ## l = (e); \
                                        TKRGuardStatus v__ ## l = (v); \
                                        e__ ## l == v__ ## l ? \
                                        (void)nil : \
                                        TKRGUARD_FAILE(@"%@", [TKRGuard guideMessageWithExpected:e__ ## l  \
                                                                                             got:v__ ## l])
#define TKRAssertEqualStatus_(v, e, l) TKRAssertEqualStatus__(v, e, l)
#define TKRAssertEqualStatus(v, e) TKRAssertEqualStatus_(v, e, __LINE__)

#if !defined(UNUSE_TKRGUARD_SHORTHAND)

#define WAIT TKRGuardStatusTimeouted != [TKRGuard waitForKey:TKRGUARD_KEY] ? \
                        (void)nil : TKRGUARD_TIMEOUT
#define WAIT_MAX(t) TKRGuardStatusTimeouted != [TKRGuard waitWithTimeout:(t) forKey:TKRGUARD_KEY] ? \
                        (void)nil : TKRGUARD_TIMEOUT
#define WAIT_TIMES(t) TKRGuardStatusTimeouted != [TKRGuard waitForKey:TKRGUARD_KEY times:(t)] ? \
                        (void)nil : TKRGUARD_TIMEOUT
#define WAIT_FOR(s) TKRAssertEqualStatus([TKRGuard waitForKey:TKRGUARD_KEY], (s))

#define RESUME [TKRGuard resumeForKey:TKRGUARD_KEY]
#define RESUME_WITH(s) [TKRGuard resumeWithStatus:(s) forKey:TKRGUARD_KEY]

#endif

#if !defined(NOTALLOW_TKRGUARD_DELAYWAIT)
#define ALLOW_TKRGUARD_DELAYWAIT
#endif

@interface TKRGuard : NSObject

+ (TKRGuardStatus)waitForKey:(id)key;
+ (TKRGuardStatus)waitForKey:(id)key times:(NSUInteger)times;
+ (TKRGuardStatus)waitWithTimeout:(NSTimeInterval)timeout forKey:(id)key;
+ (TKRGuardStatus)waitWithTimeout:(NSTimeInterval)timeout forKey:(id)key times:(NSUInteger)times;

+ (void)resumeForKey:(id)key;
+ (void)resumeWithStatus:(TKRGuardStatus)status forKey:(id)key;

+ (void)setDefaultTimeoutInterval:(NSTimeInterval)timeoutInterval;
+ (void)resetDefaultTimeoutInterval;

+ (id)adjustedKey:(id)key;

+ (NSString *)guideMessageWithExpected:(TKRGuardStatus)expected got:(TKRGuardStatus)got;

@end
