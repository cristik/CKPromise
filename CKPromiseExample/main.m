//
//  main.m
//  CKPromiseExample
//
//  Created by Cristian Kocza on 30/09/15.
//  Copyright © 2015 Cristik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CKPromise.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        int N = 1000 * 1000;
        for(typeof(N) i=0; i<N; i++) {
            CKPromise *promise = [CKPromise promise];
            [promise then:^{
                return @19;
            } :^{
                
            }];
            [promise resolve: @15];
        }
    }
    return 0;
}
