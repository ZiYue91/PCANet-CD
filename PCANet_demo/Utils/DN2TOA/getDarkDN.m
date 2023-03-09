function darkDN=getDarkDN(DN,prct)
  if (nargin<2 || isempty(prct))
    prct=0.01; % 0.01percent
  end
  
  % Removing Zero pixels;
  DN=DN(DN>0);
  DN=sort(DN(:));
%   uniqueDN=double(unique(DN));
  DN=double(DN);

  cumsumDN=cumsum(DN);
  darkDN=DN(find( ((cumsumDN./cumsumDN(end)*100) <= prct), 1, 'last'));

%  
%   totalSUM=sum(DN);
%   for i=1:numel(uniqueDN)
%     partialSUM=sum(DN(DN<=uniqueDN(i)));
%     if (partialSUM/totalSUM*100 > prct )
%       darkDN=uniqueDN(max(1,i-1));
%       break
%     end
%   end
  
%   disp(['Dark DN: ' num2str(darkDN)])
end