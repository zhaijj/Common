---
title: >-
  Evolutionarily informed deep learning methods for predicting relative
  transcript abundance from DNA sequence
date: 2019-03-07 13:13:22
category: PNAS
tags:
- 深度学习
- Transcript abundance prediction
---

### 0. 简介
这篇文章是康奈尔大学**Edward S. Buckler**课题组在PNAS发表的关于预测相对表达量的文章，虽然题目说是深度学习方法，但其实本文最大的亮点在于训练数据集、测试数据集的分割。作者认为，由于生物体在进化过程中，基因之间会共享一些进化信息，因此在分割数据集的时候不能像CV领域里一样，将数据集随机分割，这样容易导致过拟合。因此这篇文章就把以预测转录本相对表达量为例，在分割数据集的时候考虑到进化信息（也就是基因家族）。至于在模型方法方面，还是采用传统的CNN。
<!-- more -->

[文章链接](https://www.pnas.org/content/early/2019/03/05/1814551116)


### 1. 摘要
- 深度学习在许多领域彻底改变了预测，并且有着与遗传学与分子生物学同样的潜力。然而，以当前形式应用这些方法忽略了生物系统内的进化依赖性，因此可能导致假阳性以及错误的结论；
- 作者因此开发了两种考虑了进化相关的机器学习模型：（i）gene-family-guided splitting; (ii）ortholog contrasts。第一种方法通过在训练集与测试集中包含不同家族信息来约束模型；第二种方法使用直系同源基因之间的进化知识比较来控制和利用训练过程中的进化分歧。
- 用mRNA表达水平预测这两种方法，得到auROC值在0.75至0.94的范围内。模型权重显示了可解释的生物学模式，导致假设3'UTR对于微调mRNA丰度水平更为重要，而5'UTR对于大规模变化更为重要。

### 2. 前言
- 深度学习尤其是CNN在图像识别以及NLP领域都取得了很大进步，这些方法也随后被应用于分子生物学、基因组学的研究当中，但是进化关系使得在生物学中正确训练和测试模型比上面提到的图像或文本分类问题更具挑战性；
- 举个例子，如果一个人想预测mRNA的表达水平，标准的图像识别方法就是将数据集随机分成Training、Validation、Testing，但是由于基因之间的共享的进化历史（基因家族相关性、基因重复等），随机分会导致各组数据之间有依赖，测试数据集不够独立。因此没有考虑进化关系的模型就会很容易出现过拟合；
- 因此作者就提出了两个基于CNN的方法（如下**Figure 1A**所示，但其实就是关于数据集的分割不同）。第一种方法，作者起名为**gene-family-guided splitting**,实则就是在分割训练集与测试集的时候将同一家族的基因分到一起，这样训练集与测试集合不存在基因家族的overlap；第二种方法为**ortholog contrasts**, 如**Figure 1B**所示，这种方法主要针对于有两个物种的预测问题，就将直系同源的基因放到一起。 
  ![Figure 1](/images/zhaijj/20190307-Fig1.png)

### 3. 结果
#### 3.1 基于DNA序列区分表达基因与为表达基因 (Differentiating Between Expressed and Unexpressed Genes Based on DNA Sequence)
- 这部分作者构建了一个模型用来区分基因是expressed or unexpressed, 也就是最常见的二分类模型，在训练的时候采取了图1中的第一种方法。
  ![Figure 2](/images/zhaijj/20190307-Fig2.png)
- **Figure 2A:** 作者首先构造了一个叫做**pseudogene**的模型，也基因的上下游1k的序列作为模型的输入；
- **Figure 2B:** 作者首先对玉米中所有的基因进行分类，这里是用了7篇文章中的422个组织的RNA-Seq数据，红色、绿色和蓝色分别代表高表达、中等表达和不表达；
- **Figure 2C:** 作者**Figure 2B**中基因的分类，分别训练了两个**pseudogene**模型，一个是**Off/On**, 也就是用中等表达和高表达作为正样本；另外一个是**Off/High**，用高表达的作为正样本，使用downsampling使得正负样本比例1:1。随机十次五折交叉验证来评估模型的准确性；
- 同时作者在补充材料**Figure S1**中证明了如果采用随机样本分割，auROC和accuracy都会提升，进一步反映了之前的基于随机分割的方法会造成over-fitting。

#### 3.2 使用直系同源对比预测两个基因中的哪一个更高表达 (Predicting Which of Two Genes Is More Highly Expressed Using Ortholog Contrasts)

- 这部分主要用来讲述如何预测直系同源的两个基因哪个基因的表达量更高，当然我并没有理解预测这个有啥用，附上文章原话**The ortholog contrast model follows a simple approach derived from phylogenetics, where the most recent common ancestor of two closely related genes can be represented as a contrast between the two. Contrasting genes in this manner directly accounts for statistical dependencies between the genes that would otherwise hamper comparison with other genes. Building on this idea, the ortholog contrast method com- pares two genes from different genomes (or alleles from the same species) to each other and predicts the difference between the expression levels of the two**；
![Figure 3](/images/zhaijj/20190307-Fig3.png)
- **Figure 3A:** 作者在这里仍然使用一个二进制模型，1代表gene1表达比gene2高，0相反，训练的时候去掉表达为0的基因；
- **Figure 3B:** 同样适用accuracy和auROC来比较不同特征是模型的精度；

#### 3.3 对CNN模型的解读揭示了对转录本丰度预测的重要特征和元件 (Interpretation of CNN Models Reveals Elements and Motifs Important for Transcript Abundance)

- 前面的分析都比较套路，这部分作者主要根据CNN中每个神经元的权重分析哪些特征对于预测转录本的相对丰度很重要。类似于传统机器学习分析中的feature importance；首先目前的模型并不能区分转录本丰度是由于合成还是降解导致的，但是未来如果用GRO-Seq，PRO-Seq等数据训练，将可能实现这个目标。

![Figure 5](/images/zhaijj/20190307-Fig4.png)

- **Figure 5A-5B:** 作者在这部分用了两种CNN可视化的方法，一个是[DeepLIFT](https://arxiv.org/abs/1704.02685)和[Occlusion](https://arxiv.org/abs/1312.6034).因此这个图展示的就是用promoter构建的pseudo模型中3‘UTR的贡献以及terminator构建模型中5’UTR的贡献，二者是互补的。A图**Off/On**模型；B图是**Off/High**模型；而且nonpseudogene的promoter信号比terminator更强，这也与**Figure 2**结论一致（单独基于promoter序列预测比单独基于terminator序列预测效果更好）。

![Figure 6](/images/zhaijj/20190307-Fig5.png)
- **Figure 6:** 接下来是**ortholog contrasts**模型的可视化，与上一个不同，terminator区域表现出更强的信号；

### 4. 讨论
#### 4.1 3'UTR对于RNA丰度的小范围变化可能更重要
XXX
#### 4.2 不同模式和训练方法的优点和缺点
XXX
#### 4.3 结论与展望
XXX

### 5. 方法
XXXX

> 本文作者:翟晶晶
> 发布日期：2019.03.14
> 更新日期：2019.03.17
