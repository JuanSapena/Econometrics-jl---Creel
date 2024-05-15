function [residual, T_order, T] = static_resid(y, x, params, T_order, T)
if nargin < 5
    T_order = -1;
    T = NaN(4, 1);
end
[T_order, T] = CKmcmc.sparse.static_resid_tt(y, x, params, T_order, T);
residual = NaN(11, 1);
    residual(1) = (y(8)) - (y(2)^(-params(4)));
    residual(2) = (y(9)) - (params(10)*exp(y(7)));
    residual(3) = (y(10)) - (T(1)*T(2));
    residual(4) = (y(11)) - (exp(y(6))*(1-params(1))*T(3)*T(4));
    residual(5) = (y(8)) - (y(8)*params(2)*(1+y(10)-params(3)));
    residual(6) = (y(9)/y(8)) - (y(11));
    residual(7) = (y(6)) - (y(6)*params(6)+params(7)*x(1));
    residual(8) = (y(7)) - (y(7)*params(8)+params(9)*x(2));
    residual(9) = (y(1)) - (T(2)*exp(y(6))*T(3));
    residual(10) = (y(5)) - (y(1)-y(2));
    residual(11) = (y(3)) - (y(5)+y(3)*(1-params(3)));
end
