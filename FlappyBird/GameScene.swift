//
//  GameScene.swift
//  FlappyBird
//
//  Created by Takahiro Koizumi on 2022/11/15.
//

//Nodeがいるときといらないときの違い
//-Soundは音だけで画面に表示するわけではないからいらない（？）

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var itemNode:SKNode!
    var bird:SKSpriteNode!
    //スコア用
    var score = 0
    var scoreLabelNode:SKLabelNode!
    //ベストスコア用
    var bestScoreLabelNode:SKLabelNode!
    //アイテムスコア用
    var itemScore = 0
    var itemScoreLabelNode:SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard
    
    //衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0
    let groundCategory: UInt32 = 1 << 1
    let wallCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    let itemCategory: UInt32 = 1 << 4

    
    //SKView上にシーンが表示されたときのメソッド
    override func didMove(to view: SKView) {
        //重力を設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self
        
        //背景色を設定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        //スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        //壁用のノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        //アイテム用ノード
        itemNode = SKNode()
        scrollNode.addChild(itemNode)
        
        //各種スプライトを生成する処理をメソッドに分割して実行
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupItem()
        
        //スコア表示ラベルの設定
        setupScoreLabel()
        
        
    }
    
    func setupGround() {
        //地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        
        //必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        //スクロールするアクションを作成
        //左方向に画像一枚分スクロールするアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
        
        //元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
        
        //左スクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        //groundのスプライトを配置する
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)
            
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )
            
            //スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            
            //スプライトに物理帯を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            //衝突カテゴリーの設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            //衝突のときに動かないように設定する
            sprite.physicsBody?.isDynamic = false
            
            //スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupCloud() {
        //雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        //必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        //スクロールするアクションを作成
        //左方向に画像一枚分スクロールするアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 5)
        
        //元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        //左スクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        //スプライトを配置する
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100//一番うしろになるようにする
            
            //スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            
            //スプライトにアクションを設定する
            sprite.run(repeatScrollCloud)
            
            //スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupWall() {
        //壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        //移動する距離を計算
        let movingDistance = self.frame.size.width + wallTexture.size().width
        //print(movingDistance)
        //画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
        
        //自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        //２つのアクションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        //鳥の画像を取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        //鳥が通り抜ける隙間の大きさを鳥のサイズの４倍にする
        let slit_length = birdSize.height * 4
        
        //隙間位置の上下の振れ幅を100ptとする
        let random_y_range: CGFloat = 100
        
        //空の中央位置を取得(y座標)
        let groundSize = SKTexture(imageNamed: "ground").size()
        let sky_centere_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        
        //空の中央位置を基準にして下側の壁の中央位置を取得
        let under_wall_center_y = sky_centere_y - slit_length / 2 - wallTexture.size().height / 2
        
        // 壁を生成するアクションを作成
        let creationWallAnimation = SKAction.run ({
            
            // 壁をまとめるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50
            
            // 下側の壁の中央位置にランダム値を足して、下側の壁の表示位置を決定する
            let random_y = CGFloat.random(in: -random_y_range...random_y_range)
            let under_wall_y = under_wall_center_y + random_y
            
            // 下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            
            //下側の壁に物理体を設定＋衝突で動かないようにする
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            under.physicsBody?.isDynamic = false
            
            // 壁をまとめるノードに下側の壁を追加
            wall.addChild(under)
            
            // 上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            //上側の壁に物理体を設定＋衝突で動かないようにする
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            upper.physicsBody?.isDynamic = false
            
            // 壁をまとめるノードに上側の壁を追加
            wall.addChild(upper)
            
            //スコアカウント用の透明な壁の作成
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            //透明な壁に物理体を作成
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.isDynamic = false
            //透明な壁の追加
            wall.addChild(scoreNode)
            
            // 壁をまとめるノードにアニメーションを設定
            wall.run(wallAnimation)
            
            // 壁を表示するノードに今回作成した壁を追加
            self.wallNode.addChild(wall)
        })
        
        // 次の壁作成までの時間待ちのアクションを作成
       // let waitTime = CGFloat.random(in: 2...5)
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        // 壁を作成->時間待ち->壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([creationWallAnimation, waitAnimation]))
        
        // 壁を表示するノードに壁の作成を無限に繰り返すアクションを設定
        wallNode.run(repeatForeverAnimation)
    }
    
    func setupBird(){
        
        // 鳥の画像を2種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        // 2種類のテクスチャを交互に変更するアニメーションを作成
        let texturesAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texturesAnimation)
        
        // スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        
        //物理体を設置
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        
        //=========================================================================================//
        //カテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        //collisionBitMask 跳ね返り
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        //衝突判定の対象となるカテゴリーの設定
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | scoreCategory | itemCategory
        
        //衝突したときに回転させない
        bird.physicsBody?.allowsRotation = false
        //==========================================================================================//
        
        // アニメーションを設定
        bird.run(flap)
        
        // スプライトを追加する
        addChild(bird)
        
    }
    
    func setupItem() {
    
        //アイテムの画像を読み込む
        let itemTexture = SKTexture(imageNamed: "apple")
        itemTexture.filteringMode = .linear
        
        //移動距離やスピードを壁と揃えるためにここでもwallを定義？
        //let wallTexture = SKTexture(imageNamed: "wall")

        //移動する距離を計算
        let movingDistance = self.frame.size.width + itemTexture.size().width

        //画面外まで移動するアクションを作成
        let moveItem = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)

        //自身を取り除くアクションを作成
        let removeItem = SKAction.removeFromParent()

        //２つのアクションを順に実行するアクションを作成
        let itemAnimation = SKAction.sequence([moveItem, removeItem])

        //上下の振れ幅を200ptとする
        let random_y_range: CGFloat = 200

        //空の中央位置(y座標) = アイテムの中央値としてみる
        let groundSize = SKTexture(imageNamed: "ground").size()
        let item_center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        
        // アイテムを生成するアクションを作成
        let creationItemAnimation = SKAction.run ({

            // アイテムをまとめるノードを作成
            let item = SKNode()
            item.position = CGPoint(x: self.frame.size.width + itemTexture.size().width / 2, y: 0)
            item.zPosition = -20

            // アイテムの中央位置にランダム値を足して、アイテムの表示位置(y座標)を決定する
            let random_y = CGFloat.random(in: -random_y_range...random_y_range)
            let item_y = item_center_y + random_y

            // appleを作成
            let apple = SKSpriteNode(texture: itemTexture)
            apple.position = CGPoint(x: 0, y: item_y)

            //appleに物理体を設定＋衝突で動かないようにする
            //isDynamicは衝突後動かないようにする
            //categoryBitMaskは衝突判定の対象を定める
            apple.physicsBody = SKPhysicsBody(circleOfRadius: itemTexture.size().width / 2)
            apple.physicsBody?.categoryBitMask = self.itemCategory
            apple.physicsBody?.isDynamic = false

            // アイテムをまとめるノードにappleを追加
            item.addChild(apple)

            // アイテムをまとめるノードにアニメーションを設定
            item.run(itemAnimation)
            
            //アイテムの表示をランダム化
            let makeApple = Bool.random()
            if makeApple == true {
                // アイテムを表示するノードに今回作成したアイテムを追加
                self.itemNode.addChild(item)
            }
        })

      // 次のアイテム作成までの時間待ちのアクションを作成
        //時間操作で壁とかぶらないようにできる？？
        let firstWaitAnimation = SKAction.wait(forDuration: 1)
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        // アイテムを作成->時間待ち->アイテムを作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([creationItemAnimation, waitAnimation]))
        
        let appleForeverAnimation = SKAction.sequence([firstWaitAnimation, repeatForeverAnimation])

        // 壁を表示するノードに壁の作成を無限に繰り返すアクションを設定
        itemNode.run(appleForeverAnimation)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if scrollNode.speed > 0 {
            //鳥の速度をゼロにする
            //仮に速度を与えると鳥はタップするほど早くなるから画面右端に来る
            bird.physicsBody?.velocity = CGVector.zero
            //鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
            
            jumpSound()
            
        }else if bird.speed == 0 {
            restart()
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        //衝突すると呼ばれる、SKPhysicsContactDelegateのメソッド
        //衝突したとき
        //-透明な壁（隙間の通過）との衝突なら＋１
        //-その他（壁か地面）ならGAMEOVER
        
        //ゲームオーバーの判定を一回にするため、なにもしない
        //スピードがすでに０のときは何もしない
        //スピードがあるときの壁との衝突で初めて作動するようにする
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "SCORE:\(score)"
            
            //ベストスコアか確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "BEST SCORE:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
        //りんごとの衝突
        }else if (contact.bodyA.categoryBitMask & itemCategory) == itemCategory || (contact.bodyB.categoryBitMask & itemCategory) == itemCategory {
            
            var getItem: SKPhysicsBody
            
            if contact.bodyA.categoryBitMask == itemCategory {
                getItem = contact.bodyA
                getItem.node?.removeFromParent()
                
            }else{
                getItem = contact.bodyB
                getItem.node?.removeFromParent()
                
            }
            //衝突したアイテムだけ消したい
            print("ItemScoreUp")
            itemScore += 1
            itemScoreLabelNode.text = "ITEM SCORE:\(itemScore)"
            
            makeSound()
            
        }else{
            print("GAMEOVER")
            
            //スクロールの停止
            scrollNode.speed = 0
            
            //衝突後は地面と反発するのみとする（リスタートするまで反発させない）
            bird.physicsBody?.collisionBitMask = groundCategory
            
            //衝突後１秒間、鳥を回転させる
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y * 0.01), duration: 1)
            
            //回転が終わったときにbirdのスピードを０にする、完全停止
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
            
            fallSound()
        }
    }
    
    func restart() {
        
        score = 0
        itemScore = 0
        //scoreにbestScoreを代入済み
        scoreLabelNode.text = "SCORE:\(score)"
        itemScoreLabelNode.text = "ITEM SCORE:\(itemScore)"
        
        //鳥を最初の位置に戻し、壁と地面の両方に反発するように戻す
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0
        
        //すべての壁、アイテムを取り除く
        wallNode.removeAllChildren()
        itemNode.removeAllChildren()
        
        //完全にreset
        wallNode.removeAllActions()
        itemNode.removeAllActions()
        setupWall()
        setupItem()
        
        //鳥の羽ばたきを戻す
        bird.speed = 1
        
        //スクロールを再開させる
        scrollNode.speed = 1
        
    }
    
    func makeSound() {
        let sound = SKAction.playSoundFileNamed("voice.mp3", waitForCompletion: true)
        run(sound)
    }
    
    func jumpSound() {
        let sound = SKAction.playSoundFileNamed("jump06.mp3", waitForCompletion: true)
        run(sound)
    }
    
    func fallSound() {
        let sound = SKAction.playSoundFileNamed("falling.mp3", waitForCompletion: true)
        run(sound)
        
        let sound2 = SKAction.playSoundFileNamed("powerdown.mp3", waitForCompletion: true)
        run(sound2)
    }
    
    func setupScoreLabel() {
        //スコア表示を作成
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.blue
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100 //一番手前にする
        //左詰めかセンタリングか右詰めかを決める
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "SCORE:\(score)"
        self.addChild(scoreLabelNode)
        
        //ベストスコア表示を作成
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.blue
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100 //一番手前にする
        //左詰めかセンタリングか右詰めかを決める
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        bestScoreLabelNode.text = "BEST SCORE:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        //アイテムスコア表示を作成
        itemScore = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.blue
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        itemScoreLabelNode.zPosition = 100 //一番手前にする
        //左詰めかセンタリングか右詰めかを決める
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "ITEM SCORE:\(itemScore)"
        self.addChild(itemScoreLabelNode)
    }
    
    
}
