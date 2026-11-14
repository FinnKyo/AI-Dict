## 2026-11-14 | 任务：加快辞典输出并只对单词出辞典

**Links:** None

### 执行上下文

- **Agent Name:** `Claude Code`
- **Model:** `claude-opus-5-5`
- **Environment:** `macOS 27.2.1 / Xcode 27.0 (27A266a)`

### 用户请求

查询单词（如 run）时，窗口先单独显示查询词，随后长时间等待才开始生成辞典解释；用户不需要模型
思考。辞典解释应改用软件设定的第一语言；辞典模式只用于单词，短语改走翻译以免误判；单词的变形和时态（如日语活用、中文 了/过/着）也要按单词出辞典。

### 变更

- `OpenRouterService` 固定发送 `reasoning_effort: "none"`。实测所选的
  `nvidia/nemotron-3-ultra-550b-a55b:free` 首个正文字符从约 3 s 降到 0.5 s；
  `openrouter/free`、`google/gemma-4-31b-it:free` 同样生效。
- 删除辞典结果单独显示的大号词头（`showBigWord`、`translateResultsTopInset`、
  `EZLanguageManager.isShortWordLength`、`EZEnglishWordMaxLength`）。辞典条目本身带
  `## 词头` 行，原先模型思考期间屏幕上只有查询词。
- `LearnerDictionary.messages` 不再接收目标语言：释义、说明、对应词和例句译文统一用第一语言；
  词头本身就是第一语言时生成单语条目，不写对应词。
- `isDictionaryQuery` 只认单词，包括单词的各种变形和时态：
  - 以空格分词的语言要求只有 1 个词，不论词形（ran、gegangen、hablé）；越南语最多 2 个音节。
  - 中、日、泰要求是 1 个实词加上只用于变形的成分：日语助动词和活用词尾
    （食べられなかった、勉強しています 的 し/て/い/ます），中文体标记 了/过/着，
    泰语时态标记 แล้ว/จะ/อยู่ 等。
  - 白名单不含 に・を・の・も 这类连接助词，所以 日本に行く、猫の手も借りたい 仍走翻译。
  - 中文另外接受系统词典能整体识别的四字成语（画蛇添足）。
  - 除词内符号（`-` `'` `.` `·` `・`）外，含任何标点都走翻译。
- 更新 `LearnerDictionaryTests`：新增变形、时态单词出辞典，短语走翻译，以及单语条目的测试。

### 设计意图

免费模型中大量是推理模型，辞典查询不需要思维链，所以直接关闭推理。不提供设置开关，因为无论
哪种查询都不需要推理。用户规定辞典解释始终用第一语言，所以辞典模式忽略语言栏的目标语言；
句子翻译仍按语言栏的目标语言。单词判定借助系统分词器和系统词典，不靠字数阈值，减少短语误判。

### 验证

- `xcodebuild build`（Debug）：成功，0 error。
- `xcodebuild test -only-testing:` LearnerDictionaryTests、OpenRouterServiceTests、
  OpenRouterAvailabilityTests、StringAnalysisTests：全部通过（第二轮新增 21 个变形用例）。
- `-testPlan LocalEnvironment` 实网 `dictionaryLookup()`：通过，完整条目约 11 s。
- 用脚本直接调用 OpenRouter 对比开关推理的首个正文字符耗时（见上）。
- 手动检查：已重启 App；未截取界面截图（无屏幕录制权限）。

### 受影响文件

- `Easydict/Swift/Service/OpenRouter/OpenRouterService.swift`
- `Easydict/Swift/Service/OpenRouter/Dictionary/LearnerDictionary.swift`
- `Easydict/Swift/Service/OpenAI/StreamService+Prompt.swift`
- `Easydict/Swift/Service/OpenAI/StreamService+UpdateResult.swift`
- `Easydict/Swift/Service/Model/QueryResult.swift`
- `Easydict/objc/ViewController/View/WordResultView/EZWordResultView.m`
- `Easydict/objc/Service/Language/EZLanguageManager.h`
- `Easydict/objc/Service/Language/EZLanguageManager.m`
- `Easydict/App/EZConst.h`
- `EasydictTests/Service/OpenRouter/LearnerDictionaryTests.swift`

### 后续事项

- 极短的变形词可能被系统语言检测判错语言，例如德语 ging 被识别为荷兰语，没有对应模板时会走翻译；
  这时可在语言栏手动指定源语言。
- 辞典模式下语言栏仍显示原目标语言，但解释实际用第一语言。
- 完整条目的生成时长取决于模型输出速度；免费模型中速度差异较大。
