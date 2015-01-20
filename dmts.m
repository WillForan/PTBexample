%
%
% delayed match-to-sample task example 
% WF 20150120
%
%
function [results, trial] = dmts(subj_date_run)
   % so key names are the same everywhere
   KbName('UnifyKeyNames');

   screenResolution=[800 600];

   % define colors
   bgColor =  [127 127 127];  ... gray background

   % define trial settings: what color will be shown, what color will compete, where the correct position will be
   trial.displayColorN   = [ 3 2 1 3 2];
   trial.wrongColor      = [ 1 3 2 2 1];
   trial.correctColorPos = [ 3 2 1 2 3];
   trial.length = 5;

   % where to draw circles

   % keys corresponding to postions in order
   keyNames={'a', 's','d'};
   keys = KbName(keyNames);

   interval=1;
   RTwin   =.9; % how long do we have to respond

   % open a PTB window to draw on
   w = Screen('OpenWindow', 0, bgColor, [0 0 screenResolution], 32, 2, 0, 4);
   %permit transparency
   Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

   npos=3;
   starttime=GetSecs()
   onset=starttime;
   results=struct();
   for trln = 1:trial.length
      %% TRIAL SETTINGS
      correctKeyN = trial.correctColorPos(trln);

      correctPosN = trial.correctColorPos(trln);
      dispColor   = trial.displayColorN(trln);

      wrongPosN   = Shuffle(setdiff(1:npos, correctPosN ));
      wrongPosN   = wrongPosN(1);
      wrongColor  = trial.wrongColor(trln);
      %% SAMPLE
      % put oval on the screen
      drawDots(w, setdiff(1:npos,[correctPosN,wrongPosN ]),dispColor  );
      [vblt,sampleOnset ] = Screen('Flip',w,onset);
      fprintf('%.3f - sample\n',sampleOnset-starttime);
      
      %% ISI
      % wait .5s and flip the screen back to empty
      drawDots(w,[],[])
      [vblt,isiOnset] = Screen('Flip',w,onset+interval);
      fprintf('%.3f - isi\n',isiOnset-starttime);

      %% MATCH
      % draw
      drawDots(w,[correctPosN,wrongPosN ],[dispColor, wrongColor]  );
      % display
      [vblt,choiceOnset] = Screen('Flip',w, onset+2*interval);
      fprintf('%.3f - Match\n',choiceOnset-starttime);
      fprintf('\t%d - correct pos (%s)\n',correctPosN,keyNames{correctPosN} );
      fprintf('\t%d - wrong pos (%s)\n',wrongPosN,keyNames{wrongPosN});

      %% RESPONSE
      % run a while loop until we time out or we have a response
      correct=-1; % no response == -1
      hitKeys=[];  % empty hitKeys
      responseTime = Inf;
      while correct < 0 && GetSecs() < choiceOnset + RTwin
          [keyPressed, responseTime, keyCode] = KbCheck;
          % did we hit any of the keys we accept (possible more than one)
          hitKeys=find(keyCode(keys));
          if length(hitKeys) ==1 && hitKeys == correctKeyN
              correct=1;
              break;
          elseif ~isempty(hitKeys)
              correct=0;
              break;
          end
     end

     % we responded, clear the screen
     if(correct>=0)
       DrawFormattedText(w,num2str(correct),'center','center'); % show some feedback
       [vblt,RTblankOnset] = Screen('Flip',w);
       fprintf('%.3f - RTBlank onset\n',RTblankOnset-starttime);
       fprintf('\t%.3f - RT\n', responseTime-choiceOnset );
     end

     fprintf('\tcorrect %d\n', correct);
      
     %% ITI
     % push another interval onto onset so the next start is delayed
     onset=onset+3*interval;

     %% SAVE
     % record results
     results.correct(trln) = correct;
     results.hitKeys{trln} = hitKeys;
  end


   %% close down
   Screen('CloseAll');
end


function onset = drawDots(w,posN, colorN,varargin)

   circleRad=20;
   [ center(1),center(2)] = RectCenter(Screen('Rect',w));
   colors = { [0   255   0  ], ... green
              [0   0   255],   ... blue
              [255 0   0  ]};  ... red
   % The first pixel is in the upper left, and the rows are horizontal
   %
   centerRect=[ center(1)-circleRad  center(2)-circleRad  center(1)+circleRad  center(2)+circleRad ];

   position.rects  = { ...
      centerRect + [ -3*circleRad 0 -3*circleRad 0], ...
      centerRect ...
      centerRect + [ +3*circleRad 0 +3*circleRad 0], ...
   };
   position.total =3;


   % varargin can be {radius,center,colors}
   if(length(varargin)>0)
    circleRad=varargin{2};
   end
   if(length(varargin)>1)
    center=varargin{2};
   end
   if(length(varargin)>2)
    colors=varargin{3};
   end

   % make sure inputs are good
   if length(posN) ~= length(colorN) 
     error('position and colors should be equal length vectors')
   end
   if max(posN) > position.total
     error('specified postion that is not defined')
   end 
   if max(colorN) > length(colors)
     error('specified color that is not defined')
   end 


   %% first draw the black dots
   for pn = 1:position.total
      position.rects{pn};
      Screen('FillOval', w ,[0 0 0], position.rects{pn});
   end 

   %% then draw any other colors in any other postion
   for pn = 1:length(posN)
      dispcolor=colors{colorN(pn)};
      Screen('FillOval', w, dispcolor, position.rects{posN(pn)});
   end

end
