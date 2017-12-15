This page gives access to the training data and evaluation script for SemEval 2018 Task 7: Semantic Relation Extraction and Classification in Scientific Papers.


Subtask 1.1 Relation classification on clean data

        1.1.text.xml  text for training data (350 abstracts with manually annotated entities)
        1.1.relations.txt relations for training data

Subtask 1.2 Relation classification on noisy data

        1.2.text.xml  text for training data (350 abstracts with automatically annotated entities)
        1.2.relations.txt  relations for training data

Subtask 2 Relation extraction and classification on clean data

        1.1.text.xml  text for training data (same data as task 1.1)
        1.1.relations.txt  relations for training data (same data as task 1.1)


The offline version of the scorer for Semeval 2018 Task 7.

    semeval2018_task7_scorer-v1.1.pl  evaluation script for Semeval 2018 Task 7
   
    Usage: perl semeval2018_task7_scorer-v1.1.pl RESULTS_FILE KEY_FILE.
    Unlike in the codalab version, you don't need to specify the subtask number on the first line: the results file will be compared to the key file given as input.

You can evaluate your results on part of the training data using the CodaLab interface. 50 abstracts were selected for 'testing' in each subtask, you need to submit your predictions for these abstracts in a zipped file by clicking on 'Participate' on the CodaLab site.

    training-eval.txt  the online evaluation on CodaLab uses these 50 abstracts, selected from the trainaing data for each subtask.



