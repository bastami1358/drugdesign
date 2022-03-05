function [R2,RMSE,R] = R2RMSE(Y,Yhat)
    R=corrcoef(Y,Yhat);
    R=R(1,2);
    R2= R.^2;
    e=Y-Yhat;
    se= e.^2;
    mse= mean(se);
    RMSE = sqrt(mse); 
end