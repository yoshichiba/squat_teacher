//
//  ContentView.swift
//  squat_teacher Watch App
//
//  Created by 千葉良晴 on 2025/09/14.
//

import SwiftUI
import CoreMotion
import WatchKit

/// スクワットの回数をカウントするクラス
/// 重力ベクトルのZ成分を用いてしゃがみ動作を検出
class SquatCounter: ObservableObject {
    private let motionManager = CMMotionManager()
    private var isDown = false
    private var zHistory: [Double] = []
    private let historySize = 5

    /// しゃがみ判定用のしきい値（重力zの平均値は腕の向きで変わるので調整可能）
    /// -1.0 = 重力方向が真下、0 = 水平
    private let deepThreshold: Double = -0.7   // しゃがみきったとき
    private let shallowThreshold: Double = -0.4 // 立ち上がり判定

    @Published var count = 0
    
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data else { return }
            self.processGravity(z: data.gravity.z)
        }
    }
    
    private func processGravity(z: Double) {
        // 最新のz値を履歴に追加して平均化（ローパスフィルタ）
        zHistory.append(z)
        if zHistory.count > historySize { zHistory.removeFirst() }
        let avgZ = zHistory.reduce(0, +) / Double(zHistory.count)
        
        // しゃがみ動作の検出
        if !isDown && avgZ < deepThreshold {
            isDown = true
        }
        
        // 立ち上がり動作の検出（しゃがんだあと shallowThreshold を超えたら1回カウント）
        if isDown && avgZ > shallowThreshold {
            isDown = false
            count += 1
            if count % 10 == 0 {
                WKInterfaceDevice.current().play(.success)
            } else {
                WKInterfaceDevice.current().play(.click)
            }
        }
    }
    
    /// カウントをリセット
    func resetCount() {
        count = 0
    }
}

/// スクワット回数を表示するメインビュー
struct ContentView: View {
    @StateObject private var counter = SquatCounter()
    
    var body: some View {
        VStack {
            // 大きな回数表示
            Text("\(counter.count)")
                .font(.system(size: 50, weight: .bold, design: .rounded))

            // ラベル
            Text("Squats")
                .font(.title2)
                .foregroundStyle(.secondary)
                .padding(.bottom, 20)
            
            Spacer(minLength: 3)
            
            // リセットボタン
            Button(action: {
                counter.resetCount()
            }) {
                Text("Reset")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.yellow.opacity(0.3))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

