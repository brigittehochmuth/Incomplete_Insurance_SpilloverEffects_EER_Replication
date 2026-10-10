function fingerprint = paper_bundle_sha256(path)
%PAPER_BUNDLE_SHA256 Return a lowercase SHA-256 digest for one file.

fid = fopen(path,'rb');
assert(fid >= 0,'FullPaperRun:HashRead', ...
    'Could not read %s.',path);
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
bytes = fread(fid,Inf,'*uint8');
engine = java.security.MessageDigest.getInstance('SHA-256');
if ~isempty(bytes)
    engine.update(typecast(bytes(:),'int8'));
end
digest = typecast(engine.digest(),'uint8');
fingerprint = lower(reshape(dec2hex(digest,2).',1,[]));
end
