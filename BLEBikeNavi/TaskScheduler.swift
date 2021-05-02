//
//  WiseRefreshStrategy.swift
//  BLEBikeNavi
//
//  Created by Alexander Lavrushko on 05/04/2021.
//

import Foundation

enum TaskSchedulerResult {
    case canExecuteNow
    case discardedByNewerTask
}

typealias SchedulerCompletion = (TaskSchedulerResult) -> Void

class TaskScheduler {
    let minTimeBetweenTasks: TimeInterval
    private var coolDownTimer: Timer?
    private var taskClosure: SchedulerCompletion?
    
    init(minTimeBetweenTasks: TimeInterval) {
        self.minTimeBetweenTasks = minTimeBetweenTasks
    }

    deinit {
        coolDownTimer?.invalidate()
    }

    func scheduleTask(_ closure: @escaping SchedulerCompletion) {
        if let lastPendingTask = taskClosure {
            lastPendingTask(.discardedByNewerTask)
        }
        taskClosure = closure
        if coolDownTimer == nil {
            executeTask()
        }
    }

    private func executeTask() {
        guard let task = taskClosure else {
            return
        }
        self.taskClosure = nil

        task(.canExecuteNow)

        coolDownTimer = Timer.scheduledTimer(withTimeInterval: minTimeBetweenTasks,
                                             repeats: false) { [weak self] (_) in
            guard let self = self else {
                return
            }
            self.coolDownTimer = nil
            self.executeTask()
        }
    }
}
