clc
clear
disp ("Loading data please wait . . . ");
[maindata,txt,raw] = xlsread('Final_data.xlsx');
strout = sprintf('Main data is %d , %d', size(maindata,1),size(maindata,2));
disp(strout);

ynanindex = any(ismissing(maindata(:,end)),2);

nanindex = any(ismissing(maindata(:,1:end-1)),1);

strout = sprintf('Removed nan is %d new data size is %d,%d', sum(nanindex), size(maindata,1),size(maindata,2));
disp(strout);

nanindex(end+1)=false;
maindata(:,nanindex) = [];

maindata = removeconstantrows(maindata);
[maindata,py] = removeconstantrows(maindata');

maindata = maindata';
strout = sprintf('Removed %d constant column, new data size is %d,%d', numel(py.remove), size(maindata,1),size(maindata,2));
disp(strout);

data = maindata(:,2:end-1);
data = (data-min(data))./(max(data)-min(data));
data(:,end+1) =log10(maindata(:,end));

nonlabeleddata = data(ynanindex,1:end-1);
monomerid = maindata(ynanindex,1);

data = data(~ynanindex,:);

bestlambda = 2.682787211878240e+02;
ncamodel = fsrnca (data(:,1:end-1),data(:,end),'verbos',1,'Lambda',bestlambda,'FitMethod','exact');
selected_feature = ncamodel.FeatureWeights;
[selected_feature,idx] = sort(selected_feature,'descend');
featureidx =idx (1:700);

[m,n] = size(data) ;

for epoch=1:10

    P = 0.70 ;
    idx = randperm(m);
    idxtrain = idx(1:round(P*m))';
    idxtest = idx(round(P*m)+1:end)';

    XTraining = data(idxtrain,featureidx) ; 
    YTraining = data(idxtrain,end);

    XTesting = data(idxtest,featureidx) ;
    YTesting = data(idxtest,end);

    Mdl = fitrsvm(XTraining,YTraining,'KernelFunction','gaussian','KernelScale','auto','Standardize',true);
    %Mdl = fitrsvm(XTraining,YTraining,'KernelFunction','gaussian','KernelScale','auto','Standardize',true);
    predtrain= predict(Mdl,XTraining);
    predtest = predict(Mdl,XTesting);
    prednonlabel =predict(Mdl,nonlabeleddata(:,featureidx));

    [r2train , rmsetrain,rtrain] = R2RMSE(YTraining,predtrain);
    [r2test , rmsetest,rtest] = R2RMSE(YTesting,predtest);

    disp (["Train Result : RMSE" , rmsetrain , " ,R2 " r2train , "R" , rtrain ]);
    disp (["Test Result : RMSE" , rmsetest , " ,R2 " r2test , "R", rtest ]);

    %plotregression(YTraining,predtrain)

    plot(YTraining,predtrain,'o');
    hold on
    %plotregression(YTesting,predtest,'o');
    plot(YTesting,predtest,'<');
    legend("Train data","Test data");

    xlswrite('newdata.xlsx',data);

    col_header={'MonomerID','PIC50_Observed','PIC50_Predicted','IC50_Observed','Ic50_Predicted'}; 
    T=cell(numel(idxtrain),5);
    for i=1:numel(idxtrain)
        T{i,1}=raw{idxtrain(i),1};
        T{i,2}=YTraining(i);
        T{i,3}=predtrain(i);
        T{i,4}=YTraining(i)^10;
        T{i,5}=predtrain(i)^10;
    end
    xlswrite('svm_train.xlsx',col_header,'Sheet1','A1');
    xlswrite('svm_train.xlsx',T,'Sheet1','A2');

    T=cell(numel(idxtest),5);
    for i=1:numel(idxtest)
        T{i,1}=raw{idxtest(i),1};
        T{i,2}=YTesting(i);
        T{i,3}=predtest(i);
        T{i,4}=YTesting(i)^10;
        T{i,5}=predtest(i)^10;
    end
    xlswrite('svm_test.xlsx',col_header,'Sheet1','A1');
    xlswrite('svm_test.xlsx',T,'Sheet1','A2');

    col_header={'MonomerID','IC50_Observed','IC50_Predicted'}; 
    T=cell(numel(monomerid),4);
    for i=1:numel(monomerid)
        T{i,1}=monomerid(i);
        T{i,2}=prednonlabel(i);
        T{i,3}=log10(prednonlabel(i));
    end

    xlswrite('Non_Label_svm.xlsx',col_header,'Sheet1','A1');
    xlswrite('Non_Label_svm.xlsx',T,'Sheet1','A2');
    T = cell(numel(featureidx),2);
    for i=1 : 1: numel(featureidx)
        T{i,2}= featureidx(i);
        T{i,1} =string(raw(1,featureidx(i))); 
    end
    xlswrite('feature.xlsx',T);
end


%%
