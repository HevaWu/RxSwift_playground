import UIKit
import PlaygroundSupport

import RxSwift
import RxRelay

// init variable and behaviorRelay
// observe their value changing

var disposeBag = DisposeBag()

var variable = Variable<String>("init variable")

variable.asObservable()
    .debug("=== variable: ")
    .subscribe()
    .disposed(by: disposeBag)

var behaviorRelay = BehaviorRelay<String>(value: "init relay")

behaviorRelay.asObservable()
    .debug("=== behaviorRelay: ")
    .subscribe()
    .disposed(by: disposeBag)

var behaviorSubject = BehaviorSubject<String>(value: "init subject")

behaviorSubject.asObservable()
    .debug("=== behaviorSubject: ")
    .subscribe()
    .disposed(by: disposeBag)

let error = NSError.init(domain: "rxtestErrorDomain", code: 401, userInfo: [NSLocalizedDescriptionKey: "Replace_Variable_Test Thread Error 1"])

// test single thread replacing

//var singleThreadObservable = PublishSubject<String>()
//
//singleThreadObservable
//    .observeOn(MainScheduler.instance)
//    .subscribe(onNext: { newValue in
//        variable.value = newValue
//        behaviorRelay.accept(newValue)
//        behaviorSubject.onNext(newValue)
//    }, onError: { _ in
//        variable.value = "[Error] variable"
//        behaviorRelay.accept("[Error] behaviorRelay")
//        behaviorSubject.onNext("[Error] behaviorSubject")
//    })
//    .disposed(by: disposeBag)
//
//singleThreadObservable.onNext("single 1")
//singleThreadObservable.onNext("single 2")
//
//singleThreadObservable.onError(error)
//singleThreadObservable.onNext("single 3")
//singleThreadObservable.onNext("single 4")
//
//singleThreadObservable.onCompleted()
//singleThreadObservable.onNext("single 5")
//singleThreadObservable.onNext("single 6")
//
//// dealloc/clear disposeBag
//disposeBag = DisposeBag()

/* Result:
 2020-11-29 21:07:12.870: === variable:  -> subscribed
 variable value changed: init variable
 2020-11-29 21:07:12.898: === variable:  -> Event next(init variable)
 2020-11-29 21:07:12.924: === behaviorRelay:  -> subscribed
 behaviorRelay value changed: init relay
 2020-11-29 21:07:12.924: === behaviorRelay:  -> Event next(init relay)
 2020-11-29 21:07:12.927: === behaviorSubject:  -> subscribed
 behaviorSubject value changed: init subject
 2020-11-29 21:07:12.927: === behaviorSubject:  -> Event next(init subject)
 variable value changed: single 1
 2020-11-29 21:07:12.928: === variable:  -> Event next(single 1)
 behaviorRelay value changed: single 1
 2020-11-29 21:07:12.929: === behaviorRelay:  -> Event next(single 1)
 behaviorSubject value changed: single 1
 2020-11-29 21:07:12.929: === behaviorSubject:  -> Event next(single 1)
 variable value changed: single 2
 2020-11-29 21:07:12.930: === variable:  -> Event next(single 2)
 behaviorRelay value changed: single 2
 2020-11-29 21:07:12.930: === behaviorRelay:  -> Event next(single 2)
 behaviorSubject value changed: single 2
 2020-11-29 21:07:12.931: === behaviorSubject:  -> Event next(single 2)
 variable value changed: [Error] variable
 2020-11-29 21:07:12.932: === variable:  -> Event next([Error] variable)
 behaviorRelay value changed: [Error] behaviorRelay
 2020-11-29 21:07:12.932: === behaviorRelay:  -> Event next([Error] behaviorRelay)
 behaviorSubject value changed: [Error] behaviorSubject
 2020-11-29 21:07:12.932: === behaviorSubject:  -> Event next([Error] behaviorSubject)
 2020-11-29 21:07:12.935: === variable:  -> isDisposed
 2020-11-29 21:07:12.994: === behaviorRelay:  -> isDisposed
 2020-11-29 21:07:12.994: === behaviorSubject:  -> isDisposed
 
 After error, all of three not terminate
 After main subsribe completed, all of three not terminate
 After disposeBag released, all of three released
 */

// test multi thread replacing

let thread1 = DispatchQueue(label: "Test Thread1")
let thread2 = DispatchQueue(label: "Test Thread2", qos: .utility, attributes: .concurrent, autoreleaseFrequency: .inherit)
let thread3 = DispatchQueue(label: "Test Thread3", qos: .utility, attributes: .concurrent, autoreleaseFrequency: .inherit)

var multiThreadObservable: Observable<String> = Observable.create { observer -> Disposable in
    observer.onNext("multi 1")
    observer.onNext("multi 2")
    observer.onNext("multi 3")
    
    // if we send this onError,
    // in later observing, it will skip all previous onNext, directly send onError part
//    observer.onError(error)
    observer.onCompleted()
    
    observer.onNext("multi 4")
    observer.onNext("multi 5")
    observer.onNext("multi 6")
    return Disposables.create()
}

let relayLock = NSLock()
let subjectLock = NSLock()

multiThreadObservable
    .delay(.milliseconds(100), scheduler: ConcurrentDispatchQueueScheduler(queue: thread1))
    .do(onNext: { newValue in
        let newValue = "[Thread 1] " + newValue
        variable.value = variable.value + newValue
        relayLock.lock()
        behaviorRelay.accept(behaviorRelay.value + newValue)
        relayLock.unlock()
        
        subjectLock.lock()
        behaviorSubject.onNext((try! behaviorSubject.value()) + newValue)
        subjectLock.unlock()
    }, onError: { _ in
        variable.value = "[Error] variable"
        behaviorRelay.accept("[Error] behaviorRelay")
        behaviorSubject.onNext("[Error] behaviorSubject")
    })
    .subscribe()
    .disposed(by: disposeBag)

multiThreadObservable
    .delay(.milliseconds(100), scheduler: ConcurrentDispatchQueueScheduler(queue: thread2))
    .do(onNext: { newValue in
        let newValue = "[Thread 2] " + newValue
        variable.value = variable.value + newValue
        relayLock.lock()
        behaviorRelay.accept(behaviorRelay.value + newValue)
        relayLock.unlock()
        
        subjectLock.lock()
        behaviorSubject.onNext((try! behaviorSubject.value()) + newValue)
        subjectLock.unlock()
    }, onError: { _ in
        variable.value = "[Error] variable"
        behaviorRelay.accept("[Error] behaviorRelay")
        behaviorSubject.onNext("[Error] behaviorSubject")
    })
    .subscribe()
    .disposed(by: disposeBag)

multiThreadObservable
    .delay(.milliseconds(100), scheduler: ConcurrentDispatchQueueScheduler(queue: thread3))
    .do(onNext: { newValue in
        let newValue = "[Thread 3] " + newValue
        variable.value = variable.value + newValue
        relayLock.lock()
        behaviorRelay.accept(behaviorRelay.value + newValue)
        relayLock.unlock()
        
        subjectLock.lock()
        behaviorSubject.onNext((try! behaviorSubject.value()) + newValue)
        subjectLock.unlock()
    }, onError: { _ in
        variable.value = "[Error] variable"
        behaviorRelay.accept("[Error] behaviorRelay")
        behaviorSubject.onNext("[Error] behaviorSubject")
    })
    .subscribe()
    .disposed(by: disposeBag)

// please check details comparing from here:
// https://hevawu.github.io/blog/2020/12/02/Replace-deprecated-RxSwift-Variable
