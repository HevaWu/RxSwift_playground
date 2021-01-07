import UIKit
import PlaygroundSupport

import RxSwift
import RxRelay
import RxTest

let testError = NSError.init(domain: "rxtestErrorDomain", code: 401, userInfo: [NSLocalizedDescriptionKey: "Never Completable Error 1"])
let testError2 = NSError.init(domain: "rxtestErrorDomain", code: 401, userInfo: [NSLocalizedDescriptionKey: "Never Completable Error 2"])

var test = Observable<Int>.create { observer -> Disposable in
    observer.onNext(1)
    observer.onNext(2)
    observer.onNext(3)

//    observer.onCompleted()
    observer.onError(testError)
    observer.onCompleted()
    return Disposables.create()
}

//var test_publish = PublishSubject<Int>()
//
//var test = test_publish.asObservable()

var disposeBag = DisposeBag()

class Test {
    static let shared = Test()
    var disposeBag = DisposeBag()
    
    var cache = BehaviorRelay<Int?>(value: nil)
    
    var models: Observable<Int> {
        return cache.asObservable()
            .take(1)
            .flatMap { [weak self] c -> Observable<Int> in
                guard let self = self else { return .empty() }
                if let c = c {
                    return .just(c)
                }
                return self.reload()
            }
    }

    lazy var _test = test
        .debug("=== \(#line)")
//        .do(onNext: { [weak self] value in
//            self?.cache.accept(value)
//        })
        .share(replay: 1, scope: .whileConnected)
    
    
    
    func reload() -> Observable<Int> {
        return _test.take(1)
    }
}

//test_publish.onNext(1)
//test_publish.onNext(2)
//
//test_publish.onCompleted()
//test_publish.onError(testError)
//test_publish.onCompleted()
//test_publish.onError(testError2)
//test_publish.onCompleted()


Test.shared.models
    .debug("=== \(#line)")
    .ignoreElements()
    .catch{ _ in .empty() }
    .subscribe { _ in
        print("Observable<Never>: Next")
    } onError: { _ in
        print("Observable<Never>: error")
    } onCompleted: {
        print("Observable<Never>: complete")
    } onDisposed: {
        print("Observable<Never>: dispose")
    }
    .disposed(by: disposeBag)

Test.shared.models
    .debug("=== \(#line)")
    .ignoreElements()
    .asCompletable()
    .catch{ _ in .empty() }
    .subscribe {
        print("Completable: complete")
    } onError: { _ in
        print("Completable: error")
    } onDisposed: {
        print("Completable: dispose")
    }
    .disposed(by: disposeBag)

// Test with Observable<Int>.create

/*
 2021-01-07 15:22:19.135: === 51 -> subscribed
 2021-01-07 15:22:19.159: === 40 -> subscribed
 2021-01-07 15:22:19.159: === 40 -> Event next(1)
 2021-01-07 15:22:19.159: === 51 -> Event next(1)
 2021-01-07 15:22:19.160: === 40 -> Event next(2)
 2021-01-07 15:22:19.160: === 40 -> Event next(3)
 2021-01-07 15:22:19.160: === 40 -> Event completed
 2021-01-07 15:22:19.160: === 40 -> isDisposed
 2021-01-07 15:22:19.160: === 51 -> Event completed
 Observable<Never>: complete
 Observable<Never>: dispose
 2021-01-07 15:22:19.161: === 51 -> isDisposed
 2021-01-07 15:22:19.161: === 65 -> subscribed
 2021-01-07 15:22:19.161: === 40 -> subscribed
 2021-01-07 15:22:19.161: === 40 -> Event next(1)
 2021-01-07 15:22:19.161: === 65 -> Event next(1)
 2021-01-07 15:22:19.161: === 40 -> Event next(2)
 2021-01-07 15:22:19.162: === 40 -> Event next(3)
 2021-01-07 15:22:19.162: === 40 -> Event completed
 2021-01-07 15:22:19.162: === 40 -> isDisposed
 2021-01-07 15:22:19.162: === 65 -> Event completed
 Completable: complete
 Completable: dispose
 2021-01-07 15:22:19.162: === 65 -> isDisposed
 */

// Add catch Error
/*
 2021-01-07 15:34:25.275: === 71 -> subscribed
 2021-01-07 15:34:25.295: === 47 -> subscribed
 2021-01-07 15:34:25.296: === 47 -> Event next(1)
 2021-01-07 15:34:25.296: === 71 -> Event next(1)
 2021-01-07 15:34:25.296: === 47 -> Event next(2)
 2021-01-07 15:34:25.296: === 47 -> Event next(3)
 2021-01-07 15:34:25.296: === 47 -> Event error(Error Domain=rxtestErrorDomain Code=401 "Never Completable Error 1" UserInfo={NSLocalizedDescription=Never Completable Error 1})
 2021-01-07 15:34:25.297: === 47 -> isDisposed
 2021-01-07 15:34:25.297: === 71 -> Event completed
 Observable<Never>: complete
 Observable<Never>: dispose
 2021-01-07 15:34:25.297: === 71 -> isDisposed
 2021-01-07 15:34:25.297: === 86 -> subscribed
 2021-01-07 15:34:25.298: === 47 -> subscribed
 2021-01-07 15:34:25.298: === 47 -> Event next(1)
 2021-01-07 15:34:25.298: === 86 -> Event next(1)
 2021-01-07 15:34:25.298: === 47 -> Event next(2)
 2021-01-07 15:34:25.298: === 47 -> Event next(3)
 2021-01-07 15:34:25.298: === 47 -> Event error(Error Domain=rxtestErrorDomain Code=401 "Never Completable Error 1" UserInfo={NSLocalizedDescription=Never Completable Error 1})
 2021-01-07 15:34:25.298: === 47 -> isDisposed
 2021-01-07 15:34:25.298: === 86 -> Event completed
 Completable: complete
 Completable: dispose
 2021-01-07 15:34:25.343: === 86 -> isDisposed
 */
