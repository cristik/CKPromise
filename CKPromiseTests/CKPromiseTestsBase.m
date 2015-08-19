//
//  CKPromiseTestsBase.m
//  CKPromise
//
//  Created by Cristian Kocza on 16/07/15.
//  Copyright © 2015 Cristik. All rights reserved.
//

@implementation CKPromiseTestsBase

- (void)setUp {
    [super setUp];
    promise = [CKPromise promise];
}

- (NSManagedObjectContext*)managedContext {
    NSManagedObjectModel *mom = [NSManagedObjectModel mergedModelFromBundles:@[[NSBundle bundleForClass:[self class]]]];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    [psc addPersistentStoreWithType:NSInMemoryStoreType
                      configuration:nil
                                URL:nil
                            options:nil
                              error:nil];
    NSManagedObjectContext *ctx = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    ctx.persistentStoreCoordinator = psc;
    return ctx;
}

@end
