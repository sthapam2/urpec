function [b,d] = fracturePoly(XP,YP,p,shotMap,dvals)
%[b,d] = fracturePoly(XP,YP,p,shotMap,dvals)
%Fractures polygons!
% XP: array of xpoints
% YP: array of ypoints
% p: polygon
% shotmap
% dvals for fracturing
% b: output boundaries
% d: output doses

%First figure out the variation in dose across the polygon
maxDose=max(shotMap(:));
minDose=min(shotMap(:));

shape=shotMap>0;
tt=XP.*shape;
sizeX=max(tt(:))-min(tt(:));
tt=YP.*shape;
sizeY=max(tt(:))-min(tt(:));
clear tt;

dDose=dvals(2)-dvals(1);

minSize=.05;
fracNum=3;
%max number of times we can fracture along X or Y.
maxFracX=floor(-(log(minSize)-log(sizeX))/log(fracNum));
maxFracY=floor(-(log(minSize)-log(sizeY))/log(fracNum));

fracCountX=0;
fracCountY=0;

%TODO: should get rid of a bunch of points in the shot map that we don't
%need. We're going to need to use this again and again. This should
%possibly be done one level up so this function doesn't need to keep going
%it.

if maxDose-minDose<dDose %don't need to fracture
    b=p;
    [mv,i]=min(abs(dvals-nanmean(shotMap(:))));
    d=i; %dose color
else %Need to fracture
    
    
    poly=struct;
    poly(1).x=p(:,1);
    poly(1).y=p(:,2);
    poly(1).good=0;
    
    allGood=0;
    
    figure(777); clf; hold on;
    plot(poly.x,poly.y);
    %start by fracturing into 3 along each direction
    if maxFracX>0 && maxFracY>0
        polyxy=DIVIDEXY(poly,fracNum,fracNum);
        fracCountX=fracCountX+1;
        fracCountY=fracCountY+1;
        
        while ~allGood
            while count<totPolys
                if poly(i).good=0;
                    poly(i).sizeX=
                    poly(i).sizeY=
                    %Fracture it here
                    polys=
                                        
                    polysEnd=poly(i+1:end); 
                    poly=[poly(1:i-1) polys polysEnd];
                    
                    totPolys=length(poly)
                    count=count+length(polys(:))
                    
                    
                end
            end
            %Check doses for all polygons
            %For any polygons that are not good
            %Can we fracture along X?
            %Can we fracture along Y?
            %Fracture
            %Add to polygon list
           
        end
        for i=1:3
            for j=1:3
                plot(polyxy{i,j}.x,polyxy{i,j}.y);
                %TODO: see if we need to refracture
                %Might need to put this in a while loop to make sure we
                %don't have to manually program all of the loops.
            end
        end
    end
    
end

end

