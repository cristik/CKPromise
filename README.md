 [![Build Status](https://travis-ci.org/cristik/CKPromise.svg?branch=master)](https://travis-ci.org/cristik/CKPromise)

# CKPromise

An ObjectiveC implementation of the Promises/A+ proposal.
Full specs can be found at http://promisesaplus.com/.

The implementation follows all Promise/A+ specs, excepting the ones not aplicable to ObjectiveC (specifically section 2.3.3).

The current implementation doesn't yet implement circular promise chain detection, support for this will be added later on.

## New
Added support for Swift, check the CKSwiftPromise framework (or CKSwiftPromise spec if you're using Cocoapods)

## Installation

### Via github

1. `git clone https://github.com/cristik/CKPromise.git`
2. Add the `CKPromise.xcproject` to your project/workspace
3. Link against the `CKPromise` or/and `CKSwiftPromise` targets

### Via Cocoapods
1. Add `pod 'CKPromise'`, or `pod 'CKSwiftPromise` to your Podfile
2. Run `pod install`

## Description

One of the main advantages of promises the fact that they help avoiding the callback hell. For example let's consider a sequence that adds a book, however before adding it will need to validate the book details with the server, and after inserting it will need to retrieve the whole details.

```objc
AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
NSDictionary *bookData = @{@"name": @"Harry Potter"};
void (^failureBlock)(NSError *error) = ^(NSError *error) {
if([error.domain isEqual:NSURLErrorDomain]) {
// inform the user that there was a server communication problem
} else {
// inform the user that the book could not be added (e.g. it was already added by someone else)
}
};
[manager POST:@"http://myserver.com/validator/book" 
parameters:bookData
success:^(AFHTTPRequestOperation *operation, id responseObject) {
[manager POST:@"http://myserver.com/book"
parameters:bookData
success:^(AFHTTPRequestOperation *operation, id responseObject) {
[manager GET:[@"http://myserver.com/book/" stringByAppendingString:responseObject]
parameters:nil
success:^(AFHTTPRequestOperation *operation, id responseObject) {
// inform the user that the book was added, move to the appropriate screen
} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
failureBlock(operation, error);
}];
} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
failureBlock(operation, error);
}];
} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
failureBlock(operation, error);
}];
```
This results in a cascade of 3 HTTP request calls, with 3 success+failure handlers, and lot of indented code. Promises solve this by allowing chains to be built, each handler in the chain being called after the previous completed.

```objc
AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
NSDictionary *bookData = @{@"name": @"Harry Potter"};
return [manager POST:@"http://myserver.com/validator/book" parameters:bookData].promise.done(^{
return [manager POST:@"http://myserver.com/book" parameters:bookData].promise;
}).success(^(NSString *bookId){
NSString *url = [@"http://myserver.com/book/" stringByAppendingString:bookId];
return [manager GET:url parameters:nil].promise;
}).success(^(NSDictionary *bookDetails){
// inform the user that the book was added, move to the appropriate screen
}).failure(^(NSError *error) {
if([error.domain isEqual:NSURLErrorDomain]) {
// inform the user that there was a server communication problem
} else {
// inform the user that the book could not be added (e.g. it was already added by someone else)
}
});
```
Moreover, only one failure callback is needed, as if any promise in the chain fails, then the chain will automatically advance to the failure hanlder, without executing the other ones.

There are other many benefits of using promises, you can read more about them on my series of articles on promises: http://blog.cristik.com/2015/03/promises-and-objectivec-no-more-callback-hell/.

## Usage

You can create a promise either by using `[[CKPromise alloc] init]` or by using the convenience initializer `[CKPromise promise]`.

Once you own a promise, you can resolve or reject it by calling the appropriate methods: `resolve:`, or `reject:`.

If you want to add callbacks to track the promise resolution, you can use the following:
- `then::` method, which allows passing two callbacks, one for success and one for failure. 
Example:
```objc
[promise then: ^{
NSLog(@"Succeeded");
} :^(NSError* err){
NSLog(@"Failed: %@", err);
}];
```
- `then` property, which returns a block that accepts two parameters, these being the callbacks for success/failure
Example:
```objc
promise.then(^(NSNumber *count){
NSLog(@"Number of records: %@", count);
}, ^{
NSLog(@"Failed");
});
```
- the dispatch queue variants of `then::` and `then`, which allows specifying the dispatch queue the callback should be executed. By default the callbacks are scheduled on the main thread, please use these methods if you need otherwise.
- the other convenience methods/properties: `then:`, `success:`, `success`, `failure:`, `failure`, `always:`, `always`

The callback parameters are very versatile, allowing the callbacks to either return and id, or return nothing (void), and to receive either one parameter, or none (depending you are interested in the result or fail reason of the promise). Thus, all following callbacks are legal:

```objc
void^(){}
void^(id value){}
void^(NSNumber *result){}
id^(){return @15;}
id^(NSError *err){NSLog(@"Failed with error: %@", error); return [CKPromise rejected:err];}
```

This allows very custom promise chains, for example:
```objc
[backgroundManagedObjectContext insertNewObject:@"User"].success(CKPromise* ^(NSString *uuid){
return [mainObjectConext fetchObjectOfType:@"User" withId:uuid];
}).success(void ^(NSManagedObjectContext *user){
//send the user to UI
}).failure(void ^(NSError* err){
NSLog(@"Encountered an error: %@", err);
})
```
