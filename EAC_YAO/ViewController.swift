//
//  ViewController.swift
//  EAC_YAO
//
//  Created by Johnny_Yao on 2017/5/7.
//  Copyright © 2017年 Johnny_Yao. All rights reserved.
//

import UIKit
import Foundation//For CBridge
import CSVImporter//Csv Parser
import CoreData
let instanceOfJiebaController: JiebaController = JiebaController()
let moc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext //CoreData
extension Array
{
    /** Randomizes the order of an array's elements. */
    mutating func shuffle()
    {
        for _ in 0..<10
        {
            sort { (_,_) in arc4random() < arc4random() }
        }
    }
}
class Emotion_Dict {//情感字典
    var Pos_Dict: [String]?
    var Neg_Dict: [String]?
    var Over_Dict: [String]?
    var Insu_Dict: [String]?
    var Ish_Dict: [String]?
    var Very_Dict: [String]?
    var More_Dict: [String]?
    var Most_Dict: [String]?
    var Invert_Dict: [String]?
}

class Emotion_Sentence {//情感字+情感分數
    var Sentence : String?
    var Score : Float?
}
class Emotion_Feature {//歌詞情感特徵To SVM
    var Pos_Amount: Int = 0
    var Neg_Amount: Int = 0
    var Pos_Score: Float = 0
    var Neg_Score: Float = 0
    var Pos_Avg_Amount: Float = 0
    var Neg_Avg_Amount: Float = 0
    var Pos_Avg_Score: Float = 0
    var Neg_Avg_Score: Float = 0
    var Song_ID : Int = 0
}
class CSV_Lyric {
    var Name: String
    var Singer: String
    var Lyric: String
    var Answer: String
    init(Name: String, Singer : String, Lyric : String, Answer : String){
        self.Answer=Answer
        self.Lyric=Lyric
        self.Name=Name
        self.Singer=Singer
    }
}

let emotion_dict: Emotion_Dict = Emotion_Dict()
var emotion_feature_User :Emotion_Feature = Emotion_Feature()
let myEntityName = "Song_Feature"
class ViewController: UIViewController , UITextViewDelegate{
    @IBAction func svmStart(_ sender: Any) {
        SVMStart()
    }
    @IBAction func segStart(_ sender: UIButton) {
        emotion_feature_User = segFunc(stringtoseg: choursTextView.text,songID: 0)
         }
    @IBOutlet weak var verseTextView: UITextView!
    @IBOutlet weak var prechorusTextView: UITextView!
    @IBOutlet weak var choursTextView: UITextView!
    @IBOutlet weak var bridgeTextView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //qsearhAPI()
        //initializeJS()
        Emotion_Dict_init()//情緒字典載入
        verseTextView.delegate=self
        prechorusTextView.delegate=self
        choursTextView.delegate=self
        bridgeTextView.delegate=self
        instanceOfJiebaController.jiebaInitial()
        }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func SVMStart() {
        //先判定CoreData有沒有存了資料 沒有才運算
        let request = NSFetchRequest<NSFetchRequestResult>(entityName :myEntityName)
        var coredataready :Bool = false
        request.sortDescriptors = [NSSortDescriptor(key: "song_id",ascending:true)]
        do {
            let results =
                try moc.fetch(request) as! [Song_Feature]
            for result in results {
                print("\(result.song_id)")
                coredataready = true
            }
        } catch {
            fatalError("\(error)")
        }
        //=====
        if !coredataready {
        let path = "/Users/Johnny/Library/Mobile Documents/com~apple~CloudDocs/EAC_YAO/EAC_YAO/Lyric_SVM_data.csv"
        let importer = CSVImporter<CSV_Lyric>(path: path)
        importer.startImportingRecords {recordValues -> CSV_Lyric in
            return CSV_Lyric(Name: recordValues[0], Singer: recordValues[1], Lyric: recordValues[2], Answer:recordValues[3])
            }.onFinish { importedRecord in
                self.SVMProcess(importedRecord: importedRecord, coredataready: coredataready)
                }
                print("CSV Done")
        }
        else {
            let empty : [CSV_Lyric] = [CSV_Lyric]()
            self.SVMProcess(importedRecord: empty, coredataready: coredataready)
        }
        }
    func SVMProcess(importedRecord : [CSV_Lyric],coredataready : Bool){
        //var dataArray : [CSV_Lyric] = [CSV_Lyric]()//CSV讀入的資料
        let data = DataSet(dataType: .Classification, inputDimension: 8, outputDimension: 1)
        let testData = DataSet(dataType: .Classification, inputDimension: 8, outputDimension: 1)
        var flag = coredataready
        if !flag { //Core Data尚無Emotion Feature
        for (index,element) in importedRecord.enumerated(){
            let emotionfeature = segFunc(stringtoseg: element.Lyric,songID: index+1)
            //core data write
            let song_feature = NSEntityDescription.insertNewObject(
                forEntityName: myEntityName, into: moc)
                    as! Song_Feature
            song_feature.song_id = Int16(emotionfeature.Song_ID)
            song_feature.neg_amount = Int16(emotionfeature.Neg_Amount)
            song_feature.neg_score = emotionfeature.Neg_Score
            song_feature.neg_avg_score = emotionfeature.Neg_Avg_Score
            song_feature.neg_avg_amount = emotionfeature.Neg_Avg_Amount
            song_feature.pos_score = emotionfeature.Pos_Score
            song_feature.pos_amount = Int16(emotionfeature.Pos_Amount)
            song_feature.pos_avg_score = emotionfeature.Pos_Avg_Score
            song_feature.pos_avg_amount = emotionfeature.Pos_Avg_Amount
            do {
                try moc.save()
            } catch {
                fatalError("\(error)")
            }
            //core data write finish
            /*let inputfeature :[Double] = [Double(emotionfeature.Pos_Amount),Double(emotionfeature.Neg_Amount),Double(emotionfeature.Pos_Score),Double(emotionfeature.Neg_Score),Double(emotionfeature.Pos_Avg_Amount),Double(emotionfeature.Neg_Avg_Amount),Double(emotionfeature.Pos_Avg_Score),Double(emotionfeature.Neg_Avg_Score)]
            do{
                var answer = element.Answer.characters.map{String($0)}
                song_feature.song_answer = Int16(String(answer[0]))!
                try data.addDataPoint(input: inputfeature, output: Int(String(answer[0]))!)
                print(element.Answer)
            }
            catch{
                print("SVM Error")
            }*/
        }
        //print("SVMSuccess")
            flag = true
        }
        else if flag {//core data已有Emotion Feature
            // select
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: myEntityName)//core data
            // 依 id 由小到大排序
            request.sortDescriptors = [NSSortDescriptor(key: "song_id", ascending: true)]
            do {
                var song_feature =
                    try moc.fetch(request) as! [Song_Feature]
                song_feature.shuffle()//把資料隨機打散
                for (index, result) in song_feature.enumerated() {
                    if ((index+1)%10 != 0){//加入Train data
                    let inputfeature :[Double] = [Double(result.pos_amount),Double(result.neg_amount),Double(result.pos_score),Double(result.neg_score),Double(result.pos_avg_amount),Double(result.neg_avg_amount),Double(result.pos_avg_score),Double(result.neg_avg_score)]
                    do{
                        try data.addDataPoint(input: inputfeature, output: Int(result.song_answer))
                        print(result.song_id,result.song_answer)
                    }
                    catch{
                        print("SVM Error")
                    }
                    }
                    else { //SVM後 加入TestData
                        //svm traning
                        let svm = SVMModel(problemType: .C_SVM_Classification, kernelSettings:
                            KernelParameters(type: .RadialBasisFunction, degree: 0, gamma: 0.5, coef0: 0.0))
                        svm.train(data: data)
                        // Create test dataset
                        let inputfeature :[Double] = [Double(result.pos_amount),Double(result.neg_amount),Double(result.pos_score),Double(result.neg_score),Double(result.pos_avg_amount),Double(result.neg_avg_amount),Double(result.pos_avg_score),Double(result.neg_avg_score)]
                        do {
                            try testData.addTestDataPoint(input: inputfeature)    //  Expect 1
                            }
                        catch {
                            print("Invalid data set created")
                        }
                        //  Predict on the test data
                        svm.predictValues(data: testData)
                        var classLabel : Int
                        do {
                            try classLabel = testData.getClass(index: 0)
                            print(classLabel == Int(result.song_answer), "first test data point, expect 1")
                        }
                        catch {
                            print("Error in prediction")
                        }
                    }
                }
            } catch {
                fatalError("\(error)")
            }
            print("SVMSuccess")
        }
    }
    
    func segFunc (stringtoseg : String, songID : Int) -> Emotion_Feature {
    var lyricString = (instanceOfJiebaController.ready(toSeg: stringtoseg).components(separatedBy: ["\"",","," "]))
    lyricString = lyricString.filter { $0 != "" }
    lyricString = lyricString.filter { $0 != "[" }
    lyricString = lyricString.filter { $0 != "]" }
    lyricString = lyricString.filter { $0 != "\n" }
    lyricString = lyricString.filter { $0 != "." }
    lyricString = lyricString.filter { $0 != "(" }
    lyricString = lyricString.filter { $0 != ")" }
    lyricString = lyricString.filter { $0 != "\r" }
    lyricString = lyricString.filter { $0 != "~" }
    //print(lyricString)
    return Lyric_Emotion_Calc(LyricForCalc: lyricString, songID : songID)
}
    func Lyric_Emotion_Calc(LyricForCalc: [String], songID : Int) -> Emotion_Feature{
        var thisisemotionword :Bool = false
        var emotion_sentence: [Emotion_Sentence]! = [Emotion_Sentence]()
        for (index,wordForCalc) in LyricForCalc.enumerated(){
            if (wordForCalc != " " && wordForCalc != "　") {//非空格
                for wordForCompare in emotion_dict.Pos_Dict!{//Positive 比對
                    if wordForCalc == wordForCompare{//若是情緒字
                        thisisemotionword = true
                        if((index-1)>=0){
                            let weight1 = Emotion_Weight_Calc(wordForCompare: LyricForCalc[index-1],mode:0)//第一次 mode=0
                            let tempEmotionSentence : Emotion_Sentence = Emotion_Sentence()
                            if (weight1 != 1 && (index-2)>=0){//當前一字成功 且 還有前二字可抓時
                                if(weight1 == -1){//當前一字是否定詞時
                                    let weight2 = Emotion_Weight_Calc(wordForCompare: LyricForCalc[index-2],mode:1)//前一字為否定詞 mode=1
                                    if weight2 != 1{//當前二字有程度詞時
                                        tempEmotionSentence.Score = weight2 * weight1
                                        tempEmotionSentence.Sentence = LyricForCalc[index-2] + LyricForCalc[index-1] + LyricForCalc[index]
                                        emotion_sentence.append(tempEmotionSentence)
                                    }
                                    else {//當前二字沒有程度詞時
                                        tempEmotionSentence.Score = weight1
                                        tempEmotionSentence.Sentence = LyricForCalc[index-1] + LyricForCalc[index]
                                        emotion_sentence.append(tempEmotionSentence)
                                    }
                                }
                                else {//當前一字是程度詞時
                                    let weight2 = Emotion_Weight_Calc(wordForCompare: LyricForCalc[index-2],mode:2)//前一字為程度詞 mode=2
                                    if weight2 != 1{//當前二字有否定詞時
                                        tempEmotionSentence.Score = weight2 * weight1 * (-1) * 0.5
                                        tempEmotionSentence.Sentence = LyricForCalc[index-2] + LyricForCalc[index-1] + LyricForCalc[index]
                                        emotion_sentence.append(tempEmotionSentence)
                                    }
                                    else {//當前二字沒有程度詞時
                                        tempEmotionSentence.Score = weight1
                                        tempEmotionSentence.Sentence = LyricForCalc[index-1] + LyricForCalc[index]
                                        emotion_sentence.append(tempEmotionSentence)
                                    }

                                }
                            }
                            else if(weight1 != 1 && (index-2)<0){//當前一字成功 且 沒有前二字可抓時
                                tempEmotionSentence.Score = weight1
                                tempEmotionSentence.Sentence = LyricForCalc[index-1] + LyricForCalc[index]
                                emotion_sentence.append(tempEmotionSentence)
                            }
                            else {//當前一字失敗
                                tempEmotionSentence.Score = 1
                                tempEmotionSentence.Sentence = LyricForCalc[index]
                                emotion_sentence.append(tempEmotionSentence)
                            }
                        }
                        //print(wordForCalc)
                        break
                    }
                }
                if !thisisemotionword{
                for wordForCompare in emotion_dict.Neg_Dict!{//Negative 比對
                    if wordForCalc == wordForCompare{//若是情緒字
                        thisisemotionword = true
                        if((index-1)>=0){
                            let weight1 = Emotion_Weight_Calc(wordForCompare: LyricForCalc[index-1],mode:0)//第一次 mode=0
                            let tempEmotionSentence : Emotion_Sentence = Emotion_Sentence()
                            if (weight1 != 1 && (index-2)>=0){//當前一字成功 且 還有前二字可抓時
                                if(weight1 == -1){//當前一字是否定詞時
                                    let weight2 = Emotion_Weight_Calc(wordForCompare: LyricForCalc[index-2],mode:1)//前一字為否定詞 mode=1
                                    if weight2 != 1{//當前二字有程度詞時
                                        tempEmotionSentence.Score = weight2 * weight1 * (-1)
                                        tempEmotionSentence.Sentence = LyricForCalc[index-2] + LyricForCalc[index-1] + LyricForCalc[index]
                                        emotion_sentence.append(tempEmotionSentence)
                                    }
                                    else {//當前二字沒有程度詞時
                                        tempEmotionSentence.Score = weight1 * (-1)
                                        tempEmotionSentence.Sentence = LyricForCalc[index-1] + LyricForCalc[index]
                                        emotion_sentence.append(tempEmotionSentence)
                                    }
                                }
                                else {//當前一字是程度詞時
                                    let weight2 = Emotion_Weight_Calc(wordForCompare: LyricForCalc[index-2],mode:2)//前一字為程度詞 mode=2
                                    if weight2 != 1{//當前二字有否定詞時
                                        tempEmotionSentence.Score = weight2 * weight1  * 0.5
                                        tempEmotionSentence.Sentence = LyricForCalc[index-2] + LyricForCalc[index-1] + LyricForCalc[index]
                                        emotion_sentence.append(tempEmotionSentence)
                                    }
                                    else {//當前二字沒有程度詞時
                                        tempEmotionSentence.Score = weight1 * (-1)
                                        tempEmotionSentence.Sentence = LyricForCalc[index-1] + LyricForCalc[index]
                                        emotion_sentence.append(tempEmotionSentence)
                                    }
                                    
                                }
                            }
                            else if(weight1 != 1 && (index-2)<0){//當前一字成功 且 沒有前二字可抓時
                                tempEmotionSentence.Score = weight1 * (-1)
                                tempEmotionSentence.Sentence = LyricForCalc[index-1] + LyricForCalc[index]
                                emotion_sentence.append(tempEmotionSentence)
                            }
                            else {//當前一字失敗
                                tempEmotionSentence.Score = -1
                                tempEmotionSentence.Sentence = LyricForCalc[index]
                                emotion_sentence.append(tempEmotionSentence)
                            }
                        }
                        //print(wordForCalc)
                        break
                    }
                }
                }
            }
            thisisemotionword = false
        }
        for item in emotion_sentence{
            print(item.Score!,item.Sentence!)
        }
        return Emotion_Feature_Calc(data: emotion_sentence, songID : songID)
    }
    func Emotion_Feature_Calc(data: [Emotion_Sentence],songID : Int) -> Emotion_Feature{
        let emotion_feature :Emotion_Feature = Emotion_Feature()
        for element in data{
            if (element.Score! > 0){//正向特徵統計
                emotion_feature.Pos_Amount += 1
                emotion_feature.Pos_Score += element.Score!
            }
            else {//負向特徵統計
                emotion_feature.Neg_Amount += 1
                emotion_feature.Neg_Score += element.Score!
            }
        }
        emotion_feature.Pos_Avg_Amount = (Float(emotion_feature.Pos_Amount / (emotion_feature.Pos_Amount + emotion_feature.Neg_Amount)))
        emotion_feature.Neg_Avg_Amount = (Float(emotion_feature.Neg_Amount / (emotion_feature.Pos_Amount + emotion_feature.Neg_Amount)))
        emotion_feature.Pos_Avg_Score = (Float(emotion_feature.Pos_Score / Float(emotion_feature.Pos_Amount)))
        emotion_feature.Neg_Avg_Score = (Float(emotion_feature.Neg_Score / Float(emotion_feature.Neg_Amount)))
        emotion_feature.Song_ID = songID
        return emotion_feature
    }
    func Emotion_Weight_Calc(wordForCompare: String, mode: Int) ->Float{//情感詞權重計算
        if mode != 1 {//有否定詞資格才進來
        for wordForCalc in emotion_dict.Invert_Dict!{//否定詞計算
            if wordForCalc == wordForCompare{
                return -1
            }
        }
        }
        if mode != 2 {//有程度詞資格才進來
        for wordForCalc in emotion_dict.Most_Dict!{//Most 2
            if wordForCalc == wordForCompare{
                return 2
            }
        }
        for wordForCalc in emotion_dict.Over_Dict!{//Over 1.5
            if wordForCalc == wordForCompare{
                return 1.5
            }
        }
        for wordForCalc in emotion_dict.Very_Dict!{//Very 1.25
            if wordForCalc == wordForCompare{
                return 1.25
            }
        }
        for wordForCalc in emotion_dict.More_Dict!{//More 1.2
            if wordForCalc == wordForCompare{
                return 1.2
            }
        }
        for wordForCalc in emotion_dict.Ish_Dict!{//Ish 0.8
            if wordForCalc == wordForCompare{
                return 0.8
            }
        }
        for wordForCalc in emotion_dict.Insu_Dict! {//Insu 0.5
            if wordForCalc == wordForCompare{
                return 0.5
            }
        }
        }
        return 1
    }
    func Emotion_Dict_init(){//Load Emotion Dict
        emotion_dict.Insu_Dict = try? String(contentsOfFile:"/Users/Johnny/Library/Mobile Documents/com~apple~CloudDocs/EAC_YAO/EAC_YAO/CppJieba/Emotion_dict/Insufficiently.txt").components(separatedBy: ["\n"])
        emotion_dict.Ish_Dict = try? String(contentsOfFile:"/Users/Johnny/Library/Mobile Documents/com~apple~CloudDocs/EAC_YAO/EAC_YAO/CppJieba/Emotion_dict/Ish.txt").components(separatedBy: ["\n"])
        emotion_dict.More_Dict = try? String(contentsOfFile:"/Users/Johnny/Library/Mobile Documents/com~apple~CloudDocs/EAC_YAO/EAC_YAO/CppJieba/Emotion_dict/More.txt").components(separatedBy: ["\n"])
        emotion_dict.Most_Dict = try? String(contentsOfFile:"/Users/Johnny/Library/Mobile Documents/com~apple~CloudDocs/EAC_YAO/EAC_YAO/CppJieba/Emotion_dict/Most.txt").components(separatedBy: ["\n"])
        emotion_dict.Most_Dict = try? String(contentsOfFile:"/Users/Johnny/Library/Mobile Documents/com~apple~CloudDocs/EAC_YAO/EAC_YAO/CppJieba/Emotion_dict/Most.txt").components(separatedBy: ["\n"])
        emotion_dict.Neg_Dict = try? String(contentsOfFile:"/Users/Johnny/Library/Mobile Documents/com~apple~CloudDocs/EAC_YAO/EAC_YAO/CppJieba/Emotion_dict/Negative.txt").components(separatedBy: ["\n"])
        emotion_dict.Over_Dict = try? String(contentsOfFile:"/Users/Johnny/Library/Mobile Documents/com~apple~CloudDocs/EAC_YAO/EAC_YAO/CppJieba/Emotion_dict/Over.txt").components(separatedBy: ["\n"])
        emotion_dict.Pos_Dict = try? String(contentsOfFile:"/Users/Johnny/Library/Mobile Documents/com~apple~CloudDocs/EAC_YAO/EAC_YAO/CppJieba/Emotion_dict/Positive.txt").components(separatedBy: ["\n"])
        emotion_dict.Very_Dict = try? String(contentsOfFile:"/Users/Johnny/Library/Mobile Documents/com~apple~CloudDocs/EAC_YAO/EAC_YAO/CppJieba/Emotion_dict/Very.txt").components(separatedBy: ["\n"])
        emotion_dict.Invert_Dict = try? String(contentsOfFile:"/Users/Johnny/Library/Mobile Documents/com~apple~CloudDocs/EAC_YAO/EAC_YAO/CppJieba/Emotion_dict/Invert.txt").components(separatedBy: ["\n"])
        print("Load Dict Success")
        
    }

    /*func initializeJS() {
        self.jsContext = JSContext()
        // 指定 jssource.js 檔案路徑
        if let jsSourcePath = Bundle.main.path(forResource: "require-jieba-js", ofType: "js") {
            do {
                // 將檔案內容加載到 String
                let jsSourceContents = try String(contentsOfFile: jsSourcePath)
                
                // 通過 jsContext 對象，將 jsSourceContents 中包含的腳本添加到 Javascript 運行時
                self.jsContext.evaluateScript(jsSourceContents)
            }
            catch {
                print(error.localizedDescription)
            }
        }
        self.jsContext.exceptionHandler = { context, exception in //異常處理
            print("JS Error: \(exception)")
        }
        self.jsContext.evaluateScript("function multiply(value1, value2) { return value1 * value2 ")
        
        //let textToJieba = choursTextView.text
        //let jsFunction = self.jsContext.objectForKeyedSubscript("call_jieba_cut")
        //if let result = jsFunction?.call(withArguments: [textToJieba, result]){
        //print(result.toString())
        //}
    }*/
    /*func qsearhAPI(){//Qserach 斷詞
        let parameters: Parameters = [
            "key": "98fc5d2228051f1e4d44690dd674a1eb307f16a27d4daa8201440c5f982ccbe2",
            "message":choursTextView.text,
            "format":"json"
        ]
        
        Alamofire.request("http://api.qsearch.cc/api/tokenizing/v1/segment?", method: .get, parameters: parameters).responseJSON { response in
            debugPrint(response)
            
            if let json = response.result.value {
                print("JSON: \(json)")
            }
        }
    }*/
}
