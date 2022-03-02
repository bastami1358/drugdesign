clc
clear
disp ("Loading data please wait . . . ");
maindata = xlsread('data.xlsx');
strout = sprintf('Main data is %d , %d', size(maindata,1),size(maindata,2));
disp(strout);

nanindex = any(ismissing(maindata),2);
maindata(nanindex,:) = [];
strout = sprintf('Removed nan is %d new data size is %d,%d', sum(nanindex), size(maindata,1),size(maindata,2));
disp(strout);

maindata = removeconstantrows(maindata);
[maindata,py] = removeconstantrows(maindata');
maindata = maindata';
strout = sprintf('Removed %d constant column, new data size is %d,%d', numel(py.remove), size(maindata,1),size(maindata,2));
disp(strout);
total = sum(maindata);
nonzeros = find(total>0);
data = maindata(:,1:end-1);

data = (data-min(data))./(max(data)-min(data));
data(:,end+1) = maindata(:,end);
Xtrain = data(:,1:end-1);
Ytrain = data(:,end);

rng(1) % For reproducibility 
n = length(Ytrain);
cvp = cvpartition(length(Ytrain),'kfold',5);
numvalidsets = cvp.NumTestSets;
lambdavals = linspace(0,50,20)*std(Ytrain)/n;
lossvals = zeros(length(lambdavals),numvalidsets);
for i = 1:length(lambdavals)
    disp (i)
    for k = 1:numvalidsets
        X = Xtrain(cvp.training(k),:);
        y = Ytrain(cvp.training(k),:);
        Xvalid = Xtrain(cvp.test(k),:);
        yvalid = Ytrain(cvp.test(k),:);
        
        nca = fsrnca(X,y,'FitMethod','exact', ...
             'Solver','minibatch-lbfgs','Lambda',lambdavals(i), ...
             'GradientTolerance',1e-4,'IterationLimit',30);
        lossvals(i,k) = loss(nca,Xvalid,yvalid,'LossFunction','mse');
    end
end
figure
plot(lambdavals,meanloss,'ro-')
xlabel('Lambda')
ylabel('Loss (MSE)')
grid on