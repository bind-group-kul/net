%%%%%%%%%%%%%%%%%%%%%%%%%%%%% F_plot_F.m  %%%%%%%%%%%%%%%%%%%%%%%%%%%
%% function: plot the time domain and frequency domain
%% desciption:  Pxx = net_plot(Fs,Xt)
%%              Fs: frequency of input data
%%              Xt: input data
%%              Pxx: the power spectral density
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function Pxx = net_plot(Fs,Xt)                       
dt=1/Fs;                                 
N=length(Xt);                           
Xf=fft(Xt);                              % Fourier FFT

subplot(2,1,1),hold on;plot([0:N-1]/Fs,Xt,'b');        % plot the time domain
xlabel('time/s'),title('time domain');
ylabel('amplitude');
grid on;

Pxx = abs(fft(Xt)).^2/N;
% var_Pxx = var(Pxx);
% disp(['The variance of Pxx is: ' num2str(var_Pxx)]);


hold on;
subplot(2,1,2);hold on;
plot([0:N-1]/(N*dt),Pxx,'b'); % plot the frequency domain
[peak_alpha, fre_alpha] = max( Pxx( (8*dt*N):(13*dt*N) ) );
hold on;
plot(8+[fre_alpha-1 fre_alpha-1]/(N*dt),[0 peak_alpha],'--r');
xlabel('frequency/Hz'),title('frequency domain(FFT method)');
ylabel('power spectrum');
xlim([0 40]);                       
grid on;
