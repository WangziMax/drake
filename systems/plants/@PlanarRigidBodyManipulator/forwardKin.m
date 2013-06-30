function [x,J,dJ] = forwardKin(obj,kinsol,body_ind,pts)
% computes the position of pts (given in the body frame) in the global frame
%
% @param kinsol solution structure obtained from doKinematics
% @param body_ind, an integer index for the body.  if body_ind is a
% RigidBody object, then this method will look up the index for you.
% @retval x the position of pts (given in the body frame) in the global frame
% @retval J the Jacobian, dxdq
% @retval dJ the gradients of the Jacobian, dJdq
%
% if pts is a 2xm matrix, then x will be a 2xm matrix
%  and (following our gradient convention) J will be a ((2xm)x(nq))
%  matrix, with [J1;J2;...;Jm] where Ji = dxidq
% and dJ will be a (2xm)x(nq^2) matrix

checkDirty(obj);

% todo: zap this after the transition
if isa(body_ind,'RigidBody'), error('support for passing in RigidBody objects has been removed.  please pass in the body index'); end

if (kinsol.mex)
  if (obj.mex_model_ptr==0)
    error('Drake:PlanarRigidBodyManipulator:InvalidKinematics','This kinsol is no longer valid because the mex model ptr has been deleted.');
  end
  if  ~isnumeric(pts)
    error('Drake:PlanarRigidBodyManipulator:InvalidKinematics','This kinsol is not valid because it was computed via mex, and you are now asking for an evaluation with non-numeric pts.  If you intended to use something like TaylorVar, then you must call doKinematics with use_mex = false');
  end
  
  if nargout > 2
    [x,J,dJ] = forwardKinpmex(obj.mex_model_ptr.getData,kinsol.q,body_ind-1,pts);
  elseif nargout > 1
    [x,J] = forwardKinpmex(obj.mex_model_ptr.getData,kinsol.q,body_ind-1,pts);
  else
    x = forwardKinpmex(obj.mex_model_ptr.getData,kinsol.q,body_ind-1,pts);
  end
else
  m = size(pts,2);
  pts = [pts;ones(1,m)];
  x = kinsol.T{body_ind}(1:2,:)*pts;
  if (nargout>1)
    nq = size(kinsol.dTdq{body_ind},1)/3;
    J = reshape(kinsol.dTdq{body_ind}(1:2*nq,:)*pts,nq,[])';
    if (nargout>2)
      if isempty(kinsol.ddTdqdq{body_ind})
        error('you must call doKinematics with the second derivative option enabled');
      end
      ind = repmat(1:2*nq,nq,1)+repmat((0:3*nq:3*nq*(nq-1))',1,2*nq);
      dJ = reshape(kinsol.ddTdqdq{body_ind}(ind,:)*pts,nq^2,[])';
    end
  end
end

end